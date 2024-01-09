//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./IERC20.sol";
import "./DIAOracleV2.sol";

contract MoveAsset is IERC1155Receiver {
  event Deposit(
    address indexed _nftAddress,
    address indexed _from,
    uint256 indexed _nftID,
    bool _ethdropped,
    uint256 fee
  );

  event Withdraw(
    address indexed _nftAddress,
    address indexed _from,
    uint256 indexed _nftID
  );

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  address public owner;
  uint256 public l2GasFee;
  address public gasOracle; // Gas Fee oracle for l2 gas

  uint256 public withdrawGasLimit ;

  mapping(address => mapping(uint256 => bool)) public ethdropped;

  constructor(address oracle) {
    owner = msg.sender;
    gasOracle = oracle;
  }

  function _calculateFee() public view returns (uint256) {
    (uint128 value, ) = DIAOracleV2(gasOracle).getValue(
      "GAS_ARB"
    );
    return value * withdrawGasLimit;
  }

  function _updateGasOracle(address _newOracle) external onlyOwner {
    gasOracle = _newOracle;
  }

  function _updateWithdrwaGasLimit(uint256 _newGasLimit) external onlyOwner {
    withdrawGasLimit = _newGasLimit;
  }

  function getFee() public view returns (uint256) {
    return _calculateFee();
  }

  function isFeeRequired(address _nftAddress, uint256 _nftID)
    public
    view
    returns (bool)
  {
    return ethdropped[_nftAddress][_nftID];
  }

  function deposit(uint256 _nftID, address _nftAddress) external payable {
    require(
      IERC1155(_nftAddress).isApprovedForAll(msg.sender, address(this)),
      "approve missing"
    );

    if (isFeeRequired(_nftAddress, _nftID)) {
      require(msg.value >= _calculateFee(), "missing fee");
    }

    IERC1155(_nftAddress).safeTransferFrom(
      msg.sender,
      address(this),
      _nftID,
      1,
      "0x0"
    );
    emit Deposit(
      _nftAddress,
      msg.sender,
      _nftID,
      ethdropped[_nftAddress][_nftID],
      msg.value
    );
    ethdropped[_nftAddress][_nftID] = true;
  }

  // Called by bridge service
  function _withdraw(
    address _to,
    uint256 _tokenID,
    address _nftAddress
  ) external onlyOwner {
    IERC1155(_nftAddress).safeTransferFrom(
      address(this),
      _to,
      _tokenID,
      1,
      "0x0"
    );
    emit Withdraw(_nftAddress, msg.sender, _tokenID);
  }

  function onERC1155Received(
    address,
    address,
    uint256,
    uint256,
    bytes memory
  ) public pure override returns (bytes4) {
    return
      bytes4(
        keccak256("onERC1155Received(address,address,uint256,uint256,bytes)")
      );
  }

  function supportsInterface(bytes4 interfaceId)
    public
    pure
    override
    returns (bool)
  {
    return interfaceId == type(IERC1155Receiver).interfaceId;
  }

  function onERC1155BatchReceived(
    address,
    address,
    uint256[] memory,
    uint256[] memory,
    bytes memory
  ) public pure override returns (bytes4) {
    return
      bytes4(
        keccak256(
          "onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"
        )
      );
  }

  function _withdrawETH() external onlyOwner {
    payable(msg.sender).transfer(address(this).balance);
  }

  function withdrawToken(address _tokenContract, uint8 _amount)
    external
    onlyOwner
  {
    IERC20 tokenContract = IERC20(_tokenContract);
    tokenContract.transfer(msg.sender, _amount);
  }
}
