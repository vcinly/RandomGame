pragma solidity ^0.4.20;

contract RandomGame {
  uint256[] public result;
  address public banker;
  uint256 public shares = 100;
  uint256 public sharePrice = 10 finney;
  uint256 public round = 0;
  uint256 public headFillRound = 0;
  uint256 public tailFillRound = 0;

  function RandomGame () public {
    banker = msg.sender;
    oraclize_setProof(proofType_Ledger);
  }

  modifier onlyBanker() {
    require(msg.sender == banker);
    _;
  }

  struct Sheet {
    uint256 headShare;
    uint256 tailShare;
    mapping(address => uint256) head;
    mapping(address => uint256) tail;
  }

  Sheet[] sheets;

  event newRandomNumber_bytes(bytes);
  event newRandomNumber_uint(uint);

  function betting(uint side) external payable {
    require(side == 0 || side == 1);
    uint betShare = msg.value / sharePrice;

    _betting(side, betShare, msg.sender);
  }

  function _betting(uint side, uint betShare, address sender) internal {
    if (betShare > 0) {
      side == 0 ? betHead(betShare, sender) : betTail(betShare, sender);
    }
  }

  function betHead(uint _betShare, address _sender) internal {
    if (sheets.length > headFillRound) {
      Sheet storage _sheet = sheets[headFillRound];
      if (_sheet.headShare > 0) {
        if (_sheet.headShare > _betShare) {
          _sheet.headShare -= _betShare;
          _sheet.head[_sender] += _betShare;
        } else {
          _sheet.head[_sender] += _sheet.headShare;
          _betShare -= _sheet.headShare;
          _sheet.headShare = 0;
          headFillRound++;
          _betting(0, _betShare, _sender);
        }
      } else {
        headFillRound++;
        _betting(0, _betShare, _sender);
      }
    } else {
      sheets[headFillRound] = Sheet(shares, shares);
      _betting(0, _betShare, _sender);
    }
  }

  function betTail(uint _betShare, address _sender) internal {
    if (sheets.length > tailFillRound) {
      Sheet storage _sheet = sheets[tailFillRound];
      if (_sheet.tailShare > 0) {
        if (_sheet.tailShare > _betShare) {
          _sheet.tailShare -= _betShare;
          _sheet.tail[_sender] += _betShare;
        } else {
          _sheet.tail[_sender] += _sheet.tailShare;
          _betShare -= _sheet.tailShare;
          _sheet.tailShare = 0;
          tailFillRound++;
          _betting(0, _betShare, _sender);
        }
      } else {
        tailFillRound++;
        _betting(0, _betShare, _sender);
      }
    } else {
      sheets[tailFillRound] = Sheet(shares, shares);
      _betting(0, _betShare, _sender);
    }
  }

  function getSheetShare(uint _round)
    external
    view
    returns (
             uint256 headShare,
             uint256 tailShare
  ) {
    Sheet memory s = sheets[_round];
    headShare = s.headShare;
    tailShare = s.tailShare;
  }

  function checkRound() public {
    Sheet memory _sheet = sheets[round];
    if (result.length < round + 1) {
      if (_sheet.headShare == 0 && _sheet.tailShare == 0) {
        draw(round);
      }
    }
  }

  function draw(uint _round) public external {
    uint256 rand = random(2, msg.sender);
    result.push(rand)
    reward(_round, rand);
  }

  function reward(uint round, uint side) {
    Sheet memory _sheet = sheets[round];
  }

  function maxRandom(address _address) public returns (uint256 randomNumber) {
    _seed = uint256(keccak256(
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

}
