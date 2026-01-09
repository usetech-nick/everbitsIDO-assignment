// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @dev Minimal UniswapV2Router mock
 * Only exists to prevent zero-address calls in tests
 */
contract DummyRouter {
    function WETH() external pure returns (address) {
        return address(0);
    }
}
