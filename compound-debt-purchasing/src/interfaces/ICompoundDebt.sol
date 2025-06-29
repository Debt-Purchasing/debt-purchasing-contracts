// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface ICompoundDebt {
    function initialize(address _commet) external;

    function withdraw(address asset, uint256 amount, address to) external;
}
