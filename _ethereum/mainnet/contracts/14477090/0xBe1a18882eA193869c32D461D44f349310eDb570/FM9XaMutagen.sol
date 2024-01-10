// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract FM9XaMutagen is ERC721Enumerable, Ownable {

  event MutagenCooking (address indexed buyer, uint256 tokenId);
    address payable public wallet;
    uint256 public counter;
    uint256 public endTimer;
    uint256 public totalCount = 111;
    uint256 public price = 0.111 ether; 
    string public baseURI;
    bool public started;
    string _name = 'FM9Xa Mutagen';
    string _symbol = 'FM9Xa';
    constructor(string memory _baseUri, address payable _wallet) ERC721(_name, _symbol) {
      baseURI = _baseUri;
      wallet = _wallet;
      started = true;
      transferOwnership(0x86a8A293fB94048189F76552eba5EC47bc272223);
    }

    function _baseURI() internal view virtual override returns (string memory){
      return baseURI;
    }

    function setBaseURI(string memory _newURI) public onlyOwner {
      baseURI = _newURI;
    }

    function claim() payable public {
      require(started, "Sale has not started");
      require(msg.value == price, "Invalid value sent");
      require(counter < totalCount, "Fully minted");
      if (counter == 0) {
        endTimer = block.timestamp + 111 minutes;
      }
      if (block.timestamp > endTimer) {
        require(payable(msg.sender).send(price));
        selfDestruct();
        return;
      }
      emit MutagenCooking(_msgSender(), counter);
      _mint(_msgSender(), counter); 
      ++counter;
      if (counter == totalCount) {
        selfDestruct();
        return;
      }
    }

    function selfDestruct() internal {
      started = false;
      require(wallet.send(address(this).balance));
    }

    function distroDust() external onlyOwner {
      require(wallet.send(address(this).balance));
    }
  

    function changeWallet(address payable _newWallet) external onlyOwner {
        wallet = _newWallet;
    }

    function walletInventory(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    /**
   * Override isApprovedForAll to auto-approve OS's proxy contract
   */
    function isApprovedForAll(
        address _owner,
        address _operator
    ) public override view returns (bool isOperator) {
      // if OpenSea's ERC721 Proxy Address is detected, auto-return true
        if (_operator == address(0xa5409ec958C83C3f309868babACA7c86DCB077c1)) {     // OpenSea approval
            return true;
        }
        // otherwise, use the default ERC721.isApprovedForAll()
        return ERC721.isApprovedForAll(_owner, _operator);
    }
    
    function burn(uint256 tokenId) public {
      //solhint-disable-next-line max-line-length
      require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
      _burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

}