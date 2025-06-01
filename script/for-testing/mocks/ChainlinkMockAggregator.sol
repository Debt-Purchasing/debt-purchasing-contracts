// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Mock Chainlink Aggregator for Aave Oracle Integration
 * @notice Compatible with Chainlink interface and emits events for subgraph indexing
 * @dev Provides updateable price feeds with proper event emission
 */
contract ChainlinkMockAggregator {
    int256 private _latestAnswer;
    uint256 private _latestTimestamp;
    uint256 private _latestRound;

    event AnswerUpdated(
        int256 indexed current,
        uint256 indexed roundId,
        uint256 updatedAt
    );
    event NewRound(
        uint256 indexed roundId,
        address indexed startedBy,
        uint256 startedAt
    );

    // State variables
    address public owner;

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "OracleManager: caller is not the owner");
        _;
    }

    constructor(address _owner, int256 initialAnswer) {
        owner = _owner;
        _latestAnswer = initialAnswer;
        _latestTimestamp = block.timestamp;
        _latestRound = 1;
    }

    function updateAnswer(int256 newAnswer) external onlyOwner {
        _latestRound++;
        _latestAnswer = newAnswer;
        _latestTimestamp = block.timestamp;

        emit NewRound(_latestRound, msg.sender, block.timestamp);
        emit AnswerUpdated(newAnswer, _latestRound, block.timestamp);
    }

    function latestAnswer() external view returns (int256) {
        return _latestAnswer;
    }

    function latestTimestamp() external view returns (uint256) {
        return _latestTimestamp;
    }

    function latestRound() external view returns (uint256) {
        return _latestRound;
    }

    function getAnswer(uint256) external view returns (int256) {
        return _latestAnswer;
    }

    function getTimestamp(uint256) external view returns (uint256) {
        return _latestTimestamp;
    }

    function decimals() external pure returns (uint8) {
        return 8;
    }

    function description() external pure returns (string memory) {
        return "Mock Chainlink Aggregator";
    }

    function version() external pure returns (uint256) {
        return 1;
    }
}
