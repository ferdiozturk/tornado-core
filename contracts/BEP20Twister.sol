pragma solidity 0.5.17;

import "./Twister.sol";

contract BEP20Twister is Twister {
  address public token;

  constructor(
    IVerifier _verifier,
    uint256 _denomination,
    uint32 _merkleTreeHeight,
    address _operator,
    address _token
  ) Tornado(_verifier, _denomination, _merkleTreeHeight, _operator) public {
    token = _token;
  }

  function _processDeposit() internal {
    require(msg.value == 0, "BNB value is supposed to be 0 for BEP20 instance");
    _safeBep20TransferFrom(msg.sender, address(this), denomination);
  }

  function _processWithdraw(address payable _recipient, address payable _relayer, uint256 _fee, uint256 _refund) internal {
    require(msg.value == _refund, "Incorrect refund amount received by the contract");

    _safeBep20Transfer(_recipient, denomination - _fee);
    if (_fee > 0) {
      _safeBep20Transfer(_relayer, _fee);
    }

    if (_refund > 0) {
      (bool success, ) = _recipient.call.value(_refund)("");
      if (!success) {
        // let's return _refund back to the relayer
        _relayer.transfer(_refund);
      }
    }
  }

  function _safeBep20TransferFrom(address _from, address _to, uint256 _amount) internal {
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd /* transferFrom */, _from, _to, _amount));
    require(success, "not enough allowed tokens");

    // if contract returns some data lets make sure that is `true` according to standard
    if (data.length > 0) {
      require(data.length == 32, "data length should be either 0 or 32 bytes");
      success = abi.decode(data, (bool));
      require(success, "not enough allowed tokens. Token returns false.");
    }
  }

  function _safeBep20Transfer(address _to, uint256 _amount) internal {
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb /* transfer */, _to, _amount));
    require(success, "not enough tokens");

    // if contract returns some data lets make sure that is `true` according to standard
    if (data.length > 0) {
      require(data.length == 32, "data length should be either 0 or 32 bytes");
      success = abi.decode(data, (bool));
      require(success, "not enough tokens. Token returns false.");
    }
  }
}
