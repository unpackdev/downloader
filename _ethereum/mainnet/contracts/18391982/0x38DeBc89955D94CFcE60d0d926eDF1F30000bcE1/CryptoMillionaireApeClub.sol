// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./ERC721Burnable.sol";
import "./IERC20.sol";




contract CryptoMillionaireApeClub is ERC721, ERC721URIStorage, Pausable, Ownable,  ERC721Burnable {

    mapping(uint256 => bool) private _sold;
    uint256 private _soldCount;
    uint256 private _last_id;

    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) {
    }

    function _set_last_id(uint256 last_id) internal virtual {
        _last_id = last_id;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function getSoldCount() public view returns (uint256) {
        return _soldCount;
    }

    function getLastId() public view returns (uint256) {
        return _last_id;
    }


    function mint(address to, uint256 tokenId, string memory uri)
    public
    onlyOwner
    {
        _mint(to, tokenId);
        if(_last_id < tokenId) { _last_id = tokenId; }
        _setTokenURI(tokenId, uri);
    }


    function safeMint(address to, uint256 tokenId, string memory uri)
    public
    onlyOwner
    {
        _safeMint(to, tokenId);
        if(_last_id < tokenId) { _last_id = tokenId; }
        _setTokenURI(tokenId, uri);
    }



    function _set_unsold(uint256 tokenId) internal virtual {
        if (_sold[tokenId]) {
            _sold[tokenId] = false;
            _soldCount -= 1;
        }
    }

    function setUnsold(uint256 tokenId ) public onlyOwner {
        if (!_exists(tokenId)) {
            revert("CMAC: token not exists");
        }
        _set_unsold(tokenId);
    }

    function isSold(uint256 tokenId) public view returns (bool) {
        return _sold[tokenId];
    }

    function _distribute(uint256 from, uint256 to, uint256 amount) internal virtual {
        for (uint256 i = from; i <=to; i++) {
            if (_exists(i) && _sold[i]) {
                address _receiver = ownerOf(i);
                if (notContract(_receiver))
                    { payable(_receiver).transfer(amount); }
            }
        }
    }

    function distributeToBuyers(uint256 from, uint256 to, uint256 amount)  public {
        _distribute(from, to, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
    internal
    whenNotPaused
    override(ERC721)
    {
        if (batchSize > 1) {
            revert("CMACNFT: consecutive transfers not supported");
        }
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
        if (from != address(0)) {
            if (!_sold[tokenId]) {
                _sold[tokenId] = true;
                _soldCount += 1;
            }
        }
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
        _set_unsold(tokenId);
    }

    function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721, ERC721URIStorage)
    returns (string memory)
    {
        return string(abi.encodePacked("ipfs://",super.tokenURI(tokenId),"/metadata.json"));
    }

    function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721, ERC721URIStorage)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function withdraw() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function withdrawErc20(address _tokenContract) public onlyOwner {
        IERC20 tokenContract = IERC20(_tokenContract);
        tokenContract.transfer(owner(), tokenContract.balanceOf(address(this)));
    }


    function notContract(address _a) public view returns(bool){
        uint32 size;
        assembly {
            size := extcodesize(_a)
        }
        return (size == 0);
    }


    receive() external payable {
        require(msg.value > 0, "Payouts: Value to send is 0");
        require(_soldCount > 0, "Payouts: Amount of NFT sold is 0");
        uint256 amount = msg.value/_soldCount;
        _distribute(1, _last_id, amount);
    }

    function burn(uint256 tokenId) public override onlyOwner {
        //solhint-disable-next-line max-line-length
//        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        _burn(tokenId);
    }

}



