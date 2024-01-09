pragma solidity >=0.4.22 <0.9.0;

import "./Ownable.sol";

contract KeyUpgrade is Ownable {
  WMinter public minter;

  mapping(uint => uint) public watcherId;
  mapping(uint => address) public raribleContracts;
  mapping(uint => bool) public isERC721;

  uint256 STELLAR_KEY_ID = 38;
  uint256 DATA_KEY_ID = 36;

  constructor(address _minterAddress, uint256[] memory _raribleTokenIds, uint256[] memory _watcherTokenIds, address[] memory _raribleContracts, bool[] memory _isERC721) {
    minter = WMinter(_minterAddress);

    for (uint i = 0; i < _raribleTokenIds.length; i++) {
      watcherId[_raribleTokenIds[i]] = _watcherTokenIds[i];
      raribleContracts[_raribleTokenIds[i]] = _raribleContracts[i];
      isERC721[_raribleTokenIds[i]] = _isERC721[i];
    }
  }

  function upgradeKey(uint256 _raribleTokenId, uint256 _amount) external {
    require(minter.balanceOf(msg.sender, DATA_KEY_ID) >= _amount, "User does not own enough DATA keys");

    transferWatcher(_raribleTokenId, _amount);

    uint256[] memory burnIds = new uint256[](1);
    uint256[] memory amounts = new uint256[](1);
    uint256[] memory mintIds = new uint256[](1);

    burnIds[0] = DATA_KEY_ID;
    mintIds[0] = STELLAR_KEY_ID;
    amounts[0] = _amount;

    minter.burnForMint(msg.sender, burnIds, amounts, mintIds, amounts);
  }

  function transferWatcher(uint256 _raribleTokenId, uint256 _amount) public {
    address _raribleContract = raribleContracts[_raribleTokenId];
    bool _isERC721 = isERC721[_raribleTokenId];

    require(_amount > 0, "Amount must be greater than zero");
    require(_raribleContract != address(0), "Address cannot be null");
    require(watcherId[_raribleTokenId] != 0, "Invalid Rarible token ID");

    if (_isERC721) {
      RaribleERC721 raribleERC721 = RaribleERC721(_raribleContract);
      
      require(raribleERC721.isApprovedForAll(msg.sender, address(this)) == true, "Contract is not authorized");
      require(raribleERC721.ownerOf(_raribleTokenId) == msg.sender, "User does not own this NFT");
      require(_amount == 1, "ERC721 can only burn 1");

      raribleERC721.burn(_raribleTokenId);
    } else {
      RaribleERC1155 raribleERC1155 = RaribleERC1155(_raribleContract);

      require(raribleERC1155.isApprovedForAll(msg.sender, address(this)) == true, "Contract is not authorized");
      require(raribleERC1155.balanceOf(msg.sender, _raribleTokenId) >= _amount, "User does not own this quantity of NFTs");

      raribleERC1155.burn(msg.sender, _raribleTokenId, _amount);
    }

    uint256 watcherTokenId = watcherId[_raribleTokenId];
    minter.mint(msg.sender, watcherTokenId, _amount);
  }

  function setWatcher(uint256 _raribleTokenId, uint256 _watcherTokenId, address _raribleContract, bool _isERC721) external onlyOwner() {
    watcherId[_raribleTokenId] = _watcherTokenId;
    raribleContracts[_raribleTokenId] = _raribleContract;
    isERC721[_raribleTokenId] = _isERC721;
  }
}

abstract contract RaribleERC721 {
  function isApprovedForAll(address _owner, address _operator) virtual public view returns (bool);
  function ownerOf(uint256 _tokenId) virtual public view returns (address);
  function burn(uint256 _tokenId) virtual public;
}

abstract contract RaribleERC1155 {
  function isApprovedForAll(address _owner, address _operator) virtual public view returns (bool);
  function balanceOf(address _owner, uint256 _id) virtual public view returns (uint256);
  function burn(address _owner, uint256 _id, uint256 _value) virtual public;
}

abstract contract WMinter {
  function balanceOf(address _account, uint256 _id) virtual public view returns (uint256);
  function balanceOfBatch(address[] memory _accounts, uint256[] memory _ids) virtual public view returns (uint256[] memory);

  function mint(address _to, uint256 _id, uint256 _amount) virtual public;
  function burnForMint(address _from, uint[] memory _burnIds, uint[] memory _burnAmounts, uint[] memory _mintIds, uint[] memory _mintAmounts) virtual public;
}