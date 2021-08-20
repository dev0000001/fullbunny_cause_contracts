// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import './ChangeHandler.sol';
import "./FeeManagerERC20.sol";

contract Cause is ChangeHandler, ERC1155, Ownable {

  string public constant _baseURI = "https://www.fullbunny.network/cause/";
  uint256 public constant MIN_PRICE = 1000000;
  FeeManagerERC20 public fee_manager;

  address public creator;
  uint256 public funding_goal;
  uint256 public funding_balance;
  uint256 public deadline;
  uint256 public donation_count = 0;

  uint256 public constant VOTE_PRICE = 100000000000000; // 10000000000000 ethereum price ~$3100 => 0.031 usd, 100000000000000 binance, 10000000000000000 matic
  mapping (address => bool) public approve_votes;
  uint256 public approve_count = 0;
  mapping (address => bool) public disapprove_votes;
  uint256 public disapprove_count = 0;

  event Withdrawn(address sender, uint256 pool_balance);
  event Donated(address sender, uint256 value, uint256 funding_balance);
  event Voted(address sender);

  constructor(address _creator, FeeManagerERC20 _fee_manager, string memory tokenUri, uint256 _funding_goal, uint256 number_of_days) Ownable() ChangeHandler() ERC1155(string(abi.encodePacked(_baseURI, tokenUri))) {
    require(number_of_days > 0 && number_of_days <= 90, 'Improper days length. ');
    require(_funding_goal >= MIN_PRICE, 'Low funding goal. ');

    creator = _creator;
    fee_manager = _fee_manager;
    funding_goal = _funding_goal;
    deadline = block.timestamp + (number_of_days * 1 days);
    transferOwnership(creator);
  }

  function donate() payable campaignOpen external {
    require(msg.value >= MIN_PRICE, 'Not enough money sent. ');

    _mint(msg.sender, 0, 1, '');
    donation_count++;
    funding_balance += msg.value;

    emit Donated(msg.sender, msg.value, funding_balance);
  }

  function withdraw() onlyOwner campaignClosed external {
    uint256 withdrawn_amount = funding_balance;
    funding_balance = 0;
    payable(msg.sender).transfer(withdrawn_amount);

    emit Withdrawn(msg.sender, withdrawn_amount);
  }

  function approve() payable external {
    require(msg.value >= VOTE_PRICE, 'Not enough money sent. ');
    require(!approve_votes[msg.sender], 'Already approved. ');

    apply_change(msg.sender, msg.value, VOTE_PRICE);
    apply_vote_fee();

    approve_count += 1;
    approve_votes[msg.sender] = true;

    emit Voted(msg.sender);
  }

  function disapprove() payable external {
    require(msg.value >= VOTE_PRICE, 'Not enough money sent. ');
    require(!disapprove_votes[msg.sender], 'Already disapproved. ');

    apply_change(msg.sender, msg.value, VOTE_PRICE);
    apply_vote_fee();

    disapprove_count += 1;
    disapprove_votes[msg.sender] = true;

    emit Voted(msg.sender);
  }

  modifier campaignOpen() {
    require(block.timestamp < deadline, 'Campaign is closed. ');
    _;
  }

  modifier campaignClosed() {
    require(block.timestamp >= deadline, 'Campaign is open. ');
    _;
  }

  function apply_vote_fee() internal {
    fee_manager.deposit{value: VOTE_PRICE}();
  }
}
