//SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

interface ICallerContract {
    function callback(uint256 _ethPrice, uint256 id) external;
}
