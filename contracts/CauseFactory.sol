// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './Cause.sol';
import './FeeManagerERC20.sol';

contract CauseFactory {

  Cause[] public deployed_causes;
  uint256 public cause_count = 0;
  FeeManagerERC20 fee_manager = FeeManagerERC20(payable(address(0xCA41C029c39dB0B485Bb425b69DE0A4308e4F598)));

  event CauseCreated(address sender, address fee_manager, string _tokenUri, uint256 funding_goal, uint256 number_of_days);

  function create_cause(string memory _tokenUri, uint256 funding_goal, uint256 number_of_days) public {
    Cause new_cause = new Cause(msg.sender, fee_manager, _tokenUri, funding_goal, number_of_days);
    deployed_causes.push(new_cause);
    cause_count += 1;

    emit CauseCreated(msg.sender, address(fee_manager), _tokenUri, funding_goal, number_of_days);
  }

  function get_deployed_causes() public view returns(Cause[] memory) {
    return deployed_causes;
  }

  function get_cause_owner(uint256 id) public view returns(address) {
    return deployed_causes[id].owner();
  }

  receive() payable external {
    if (msg.value > 0) payable(msg.sender).transfer(msg.value);
  }

  fallback() payable external {
    if (msg.value > 0) payable(msg.sender).transfer(msg.value);
  }
}
