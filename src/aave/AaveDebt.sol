// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@aave/core-v3/contracts/dependencies/openzeppelin/contracts/SafeERC20.sol";
import {IPool} from "@aave/core-v3/contracts/interfaces/IPool.sol";

// /**
//  * @title AaveDebt
//  * @notice A contract that acts as a wallet for managing debt positions on Aave
//  */
contract AaveDebt {
    using SafeERC20 for IERC20;

    address public router;
    IPool public aavePool;
    constructor() {}

    function initialize(IPool _aavelPool) external {
        require(router == address(0), "Already initialized");
        router = msg.sender;
        aavePool = _aavelPool;
    }

    modifier onlyRouter() {
        require(msg.sender == router, "Not router");
        _;
    }

    function borrow(
        address asset,
        uint256 amount,
        uint256 interestRateMode
    ) external onlyRouter {
        aavePool.borrow(asset, amount, interestRateMode, 0, address(this));
    }

    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external onlyRouter returns (uint256) {
        return aavePool.withdraw(asset, amount, to);
    }

    function repayWithATokens(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        address sender
    ) external onlyRouter {
        aavePool.repayWithATokens(asset, amount, interestRateMode);
        address aToken = aavePool.getReserveData(asset).aTokenAddress;

        IERC20(aToken).safeTransfer(
            sender,
            IERC20(aToken).balanceOf(address(this))
        );
    }

    function swapBorrowRateMode(
        address asset,
        uint256 interestRateMode
    ) external onlyRouter {
        aavePool.swapBorrowRateMode(asset, interestRateMode);
    }
}
