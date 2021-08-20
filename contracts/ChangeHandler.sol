// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract ChangeHandler {

  using SafeMath for uint256;

  constructor() {}

  function apply_change(address sender, uint256 value, uint256 price) internal {
    uint256 change = value.sub(price);
    if (change > 0 && value > change) {
      payable(sender).transfer(change);
    }
  }
}
