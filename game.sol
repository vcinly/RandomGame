pragma solidity ^0.4.20;

contract RandomGame {
  uint256[] public results;
  address public banker;
  uint256 public shares = 100;
  uint256 public sharePrice = 10 finney;
  uint256 public round = 0;
  uint256 public gasPrice = 0.001 szabo;

  constructor () public {
    banker = msg.sender;
  }

  modifier onlyBanker() {
    require(msg.sender == banker);
    _;
  }

  struct Chip {
    address owner;
    uint256 share;
  }

  struct Sheet {
    uint256 sharePrice;
    uint256 totalHeadShare;
    uint256 totalTailShare;
    uint256 leftHeadShare;
    uint256 leftTailShare;
    Chip[] head;
    Chip[] tail;
  }

  Sheet[] sheets;

  event newRandomNumber(uint);

  function maxRandom(address _address) public returns (uint256 randomNumber) {
    uint _seed = uint256(keccak256(
                              _address,
                              block.blockhash(block.number - 1),
                              block.coinbase,
                              block.difficulty
                              ));
    return _seed;
  }

  function random(uint256 upper, address seed) public returns (uint256 randomNumber) {
    return maxRandom(seed) % upper;
  }

  function checkLeftShare(uint side) internal returns (uint leftShare) {
    if (sheets[round].sharePrice == 0) {
      sheets[round] = Sheet({
          sharePrice: sharePrice, 
          totalHeadShare: shares, 
          totalTailShare: shares, 
          leftHeadShare:shares, 
          leftTailShare:shares,
          head: new Chip[](0),
          tail: new Chip[](0)
      });
    }

    Sheet memory _sheet = sheets[round];
    if (side == 0) {
      leftShare = _sheet.leftHeadShare;
    } else {
      leftShare = _sheet.leftTailShare;
    }
  }

  function checkBetShareAndRefund(uint _value, uint _leftShare, address _sender) internal returns(uint _betShare) {
    uint maxShare = _value / sharePrice;
    if (maxShare <= _leftShare) {
      _betShare = maxShare;
    } else {
      _betShare = _leftShare;
      uint refundFee = _value - (_leftShare * sharePrice);
      _sender.transfer(refundFee);
    }
  }


  function betting(uint side) external payable {
    require(side == 0 || side == 1);
    require(msg.value >= sharePrice);

    uint leftShare = checkLeftShare(side);

    require(leftShare > 0);

    uint betShare = checkBetShareAndRefund(msg.value, leftShare, msg.sender);

    _betting(side, betShare, msg.sender);

    checkAndDraw(msg.sender);
  }


  function _betting(uint _side, uint _betShare, address _sender) internal {
    Sheet storage _sheet = sheets[round];

    if (_side == 0) {
      _sheet.leftHeadShare -= _betShare;
      _sheet.head.push(Chip(_sender, _betShare));
    } else {
      _sheet.leftTailShare -= _betShare;
      _sheet.tail.push(Chip(_sender, _betShare));
    }
  }

  function checkAndDraw(address _sender) internal {
    Sheet memory _sheet = sheets[round];
    if (_sheet.leftHeadShare == 0 && _sheet.leftTailShare == 0) {
      uint256 rand = random(2, _sender);
      results.push(rand);
      reward(rand, _sender);
      round++;
    }
  }

  function reward(uint _rand, address _sender) internal {
    Sheet memory _sheet = sheets[round];
    Chip[] memory winners = _rand == 0 ? _sheet.head : _sheet.tail;
    uint totalShare = _rand == 0 ? _sheet.totalHeadShare : _sheet.totalTailShare;

    uint transferFee = 21000 * winners.length * gasPrice;
    uint totalBonus = ((_sheet.totalHeadShare + _sheet.totalTailShare) * _sheet.sharePrice * 98 / 100) - transferFee;

    for (uint i = 0; i < winners.length; i++) {
      Chip memory winner = winners[i];
      uint bonus = totalBonus / totalShare * winner.share;
      if (winner.owner == _sender) { bonus += transferFee; }
      winner.owner.transfer(bonus);
    }
  }
}
