// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "solecs/components/Uint256Component.sol";

uint256 constant ID = uint256(keccak256("component.Treasury"));
uint256 constant BalanceID = uint256(keccak256("component.Treasury.balance"));

contract TreasuryComponent is Uint256Component {
  constructor(address world) Uint256Component(world, ID) {}
}
