// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface IConfigurator {
    function factory(address comet) external view returns (address);
    function governor() external view returns (address);
}
