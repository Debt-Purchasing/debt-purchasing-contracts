package changeset

import (
	"errors"
	"fmt"

	"github.com/ethereum/go-ethereum/accounts/abi/bind"
	"github.com/ethereum/go-ethereum/common"

	"github.com/smartcontractkit/chainlink/deployment"
	commonchangeset "github.com/smartcontractkit/chainlink/deployment/common/changeset"
	"github.com/smartcontractkit/chainlink/deployment/common/types"

	capabilities_registry "github.com/smartcontractkit/chainlink-evm/gethwrappers/keystone/generated/capabilities_registry_1_1_0"
	forwarder "github.com/smartcontractkit/chainlink-evm/gethwrappers/keystone/generated/forwarder_1_0_0"
	ocr3_capability "github.com/smartcontractkit/chainlink-evm/gethwrappers/keystone/generated/ocr3_capability_1_0_0"
	workflow_registry "github.com/smartcontractkit/chainlink-evm/gethwrappers/workflow/generated/workflow_registry_wrapper"
)

// Ownable is an interface for contracts that have an owner.
type Ownable interface {
	Address() common.Address
	Owner(opts *bind.CallOpts) (common.Address, error)
}

// OwnedContract represents a contract and its owned MCMS contracts.
type OwnedContract[T Ownable] struct {
	// The MCMS contracts that the contract might own
	McmsContracts *commonchangeset.MCMSWithTimelockState
	// The actual contract instance
	Contract T
}

// NewOwnable creates an OwnedContract instance.
// It checks if the contract is owned by a timelock contract and loads the MCMS state if necessary.
func NewOwnable[T Ownable](contract T, ab deployment.AddressBook, chain deployment.Chain) (*OwnedContract[T], error) {
	var timelockTV = deployment.NewTypeAndVersion(types.RBACTimelock, deployment.Version1_0_0)

	// Look for MCMS contracts that might be owned by the contract
	addresses, err := ab.AddressesForChain(chain.Selector)
	if err != nil {
		return nil, fmt.Errorf("failed to get addresses: %w", err)
	}

	ownerTV, err := GetOwnerTypeAndVersion[T](contract, ab, chain)
	if err != nil {
		return nil, fmt.Errorf("failed to get owner type and version: %w", err)
	}

	// Check if the owner is a timelock contract (owned by MCMS)
	// If the owner is not in the address book (ownerTV = nil and err = nil), we assume it's not owned by MCMS
	if ownerTV != nil && ownerTV.Type == timelockTV.Type && ownerTV.Version.String() == timelockTV.Version.String() {
		// Load MCMS state
		stateMCMS, mcmsErr := commonchangeset.MaybeLoadMCMSWithTimelockChainState(chain, addresses)
		if mcmsErr != nil {
			return nil, fmt.Errorf("failed to load MCMS state: %w", mcmsErr)
		}

		return &OwnedContract[T]{
			McmsContracts: stateMCMS,
			Contract:      contract,
		}, nil
	}

	return &OwnedContract[T]{
		McmsContracts: nil,
		Contract:      contract,
	}, nil
}

// GetOwnerTypeAndVersion retrieves the owner type and version of a contract.
func GetOwnerTypeAndVersion[T Ownable](contract T, ab deployment.AddressBook, chain deployment.Chain) (*deployment.TypeAndVersion, error) {
	// Get the contract owner
	owner, err := contract.Owner(nil)
	if err != nil {
		return nil, fmt.Errorf("failed to get contract owner: %w", err)
	}

	// Look for owner in address book
	addresses, err := ab.AddressesForChain(chain.Selector)
	if err != nil {
		return nil, fmt.Errorf("failed to get addresses for chain %d: %w", chain.Selector, err)
	}

	ownerStr := owner.Hex()
	// Check if owner matches any address in the address book
	if tv, exists := addresses[ownerStr]; exists {
		return &tv, nil
	}

	// Handle case where owner is not in address book
	// Check for case-insensitive match since some addresses might be stored with different casing
	for addr, tv := range addresses {
		if common.HexToAddress(addr) == owner {
			return &tv, nil
		}
	}

	// Owner not found, assume it's non-MCMS so no error is returned
	return nil, nil
}

// GetOwnableContract retrieves a contract instance of type T from the address book.
// If `targetAddr` is provided, it will look for that specific address.
// If not, it will default to looking one contract of type T, and if it doesn't find exactly one, it will error.
func GetOwnableContract[T Ownable](ab deployment.AddressBook, chain deployment.Chain, targetAddr *string) (*T, error) {
	var contractType deployment.ContractType
	// Determine contract type based on T
	switch any(*new(T)).(type) {
	case *forwarder.KeystoneForwarder:
		contractType = KeystoneForwarder
	case *capabilities_registry.CapabilitiesRegistry:
		contractType = CapabilitiesRegistry
	case *ocr3_capability.OCR3Capability:
		contractType = OCR3Capability
	case *workflow_registry.WorkflowRegistry:
		contractType = WorkflowRegistry
	default:
		return nil, fmt.Errorf("unsupported contract type %T", *new(T))
	}

	addresses, err := ab.AddressesForChain(chain.Selector)
	if err != nil {
		return nil, fmt.Errorf("failed to get addresses for chain %d: %w", chain.Selector, err)
	}

	// If addr is provided, look for that specific address
	if targetAddr != nil {
		addr := *targetAddr
		tv, exists := addresses[addr]
		if !exists {
			return nil, fmt.Errorf("address %s not found in address book", addr)
		}

		if tv.Type != contractType {
			return nil, fmt.Errorf("address %s is not a %s, got %s", addr, contractType, tv.Type)
		}

		return createContractInstance[T](addr, chain)
	}

	var foundAddr string
	var contractCount int

	for addr, tv := range addresses {
		if tv.Type == contractType {
			contractCount++
			foundAddr = addr

			if contractCount > 1 {
				return nil, fmt.Errorf("multiple contracts of type %s found, must provide a `targetAddr`", contractType)
			}
		}
	}

	if contractCount == 0 {
		return nil, fmt.Errorf("no contract of type %s found", contractType)
	}

	return createContractInstance[T](foundAddr, chain)
}

// createContractInstance is a helper function to create contract instances
func createContractInstance[T Ownable](addr string, chain deployment.Chain) (*T, error) {
	var instance T
	var err error

	switch any(*new(T)).(type) {
	case *forwarder.KeystoneForwarder:
		c, e := forwarder.NewKeystoneForwarder(common.HexToAddress(addr), chain.Client)
		instance, err = any(c).(T), e
	case *capabilities_registry.CapabilitiesRegistry:
		c, e := capabilities_registry.NewCapabilitiesRegistry(common.HexToAddress(addr), chain.Client)
		instance, err = any(c).(T), e
	case *ocr3_capability.OCR3Capability:
		c, e := ocr3_capability.NewOCR3Capability(common.HexToAddress(addr), chain.Client)
		instance, err = any(c).(T), e
	case *workflow_registry.WorkflowRegistry:
		c, e := workflow_registry.NewWorkflowRegistry(common.HexToAddress(addr), chain.Client)
		instance, err = any(c).(T), e
	default:
		return nil, errors.New("unsupported contract type for instance creation")
	}

	if err != nil {
		return nil, fmt.Errorf("failed to create contract instance: %w", err)
	}

	return &instance, nil
}

// GetOwnedContract is a helper function that gets a contract and wraps it in OwnedContract
func GetOwnedContract[T Ownable](addressBook deployment.AddressBook, chain deployment.Chain, addr string) (*OwnedContract[T], error) {
	contract, err := GetOwnableContract[T](addressBook, chain, &addr)
	if err != nil {
		return nil, fmt.Errorf("failed to get contract at %s: %w", addr, err)
	}

	ownedContract, err := NewOwnable(*contract, addressBook, chain)
	if err != nil {
		return nil, fmt.Errorf("failed to create owned contract for %s: %w", addr, err)
	}

	return ownedContract, nil
}
