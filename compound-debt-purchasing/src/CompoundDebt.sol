// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {CometMainInterface} from "@comet/contracts/CometMainInterface.sol";
import {ICompoundDebt} from "./interfaces/ICompoundDebt.sol";

contract CompoundDebt {
    address public router;

    CometMainInterface public comet;
    constructor() {}

    function initialize(address _comet) external {
        router = msg.sender;
        comet = CometMainInterface(_comet);
    }

    modifier onlyRouter() {
        require(msg.sender == router, "Not router");
        _;
    }

    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external onlyRouter {
        comet.withdrawTo(to, asset, amount);
    }
}
