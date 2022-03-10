//SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

interface IEthPriceOracle {
    function getLatestEthPrice() external returns (uint256);
}
