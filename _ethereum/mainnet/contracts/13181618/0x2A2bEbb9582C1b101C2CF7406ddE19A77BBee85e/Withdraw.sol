pragma abicoder v2;
pragma solidity ^0.7.5;

import "./TransferHelper.sol";
import "./Ownable.sol";
import "./Context.sol";
import "./VerifierSignature.sol";

contract Withdraw is VerifierSignature, Ownable {

  address public wonderFi;
  mapping (address => mapping(bytes => bool)) public nonce;

  modifier onlyWonderFi() {
      require(wonderFi == _msgSender(), "Ownable: caller is not wonderFi");
      _;
  }

  function setWonderFiAddress(address _wonderFi) public onlyOwner {
    wonderFi = _wonderFi;
  }

  function verifyNonce(address _signer, bytes memory _nonce) private {
    require(
        nonce[_signer][_nonce] == false,
        "Invalid nonce"
    );

    nonce[_signer][_nonce] = true;
  }

  function withdraw(
    address _signer,
    address token0,
    uint256 token0Amount,
    address token1,
    uint256 token1Amount,
    bytes memory _nonce,
    bytes memory signature
    ) external onlyWonderFi {
      require(
        verifySwap(_signer, token0, token0Amount, token1, token1Amount, _nonce, signature),
        "Invalid signature"
      );

      verifyNonce(_signer, _nonce);

      TransferHelper.safeTransferFrom(token0, _signer, wonderFi, token0Amount);
  }

  function transfer(
    address _signer,
    address token0,
    uint256 token0Amount,
    address destination,
    bytes memory _nonce,
    bytes memory signature
    ) external onlyWonderFi {
      require(
        verifyTransfer(_signer, token0, token0Amount, destination, _nonce, signature),
        "Invalid signature"
      );

      verifyNonce(_signer, _nonce);

      TransferHelper.safeTransferFrom(token0, _signer, destination, token0Amount);
  }
}
