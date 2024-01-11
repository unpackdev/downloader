// SPDX-License-Identifier: MIT
/***
* $$$$$$$$\ $$\                 $$\       $$\     $$\                                   $$\                            $$\     $$$$$$$\                  $$\
* $$  _____|\__|                $$ |      \$$\   $$  |                                  $$ |                           $$ |    $$  __$$\                 $$ |
* $$ |      $$\ $$$$$$$\   $$$$$$$ |       \$$\ $$  /$$$$$$\  $$\   $$\  $$$$$$\        $$ |      $$$$$$\   $$$$$$$\ $$$$$$\   $$ |  $$ | $$$$$$\   $$$$$$$ |$$\   $$\
* $$$$$\    $$ |$$  __$$\ $$  __$$ |        \$$$$  /$$  __$$\ $$ |  $$ |$$  __$$\       $$ |     $$  __$$\ $$  _____|\_$$  _|  $$$$$$$\ |$$  __$$\ $$  __$$ |$$ |  $$ |
* $$  __|   $$ |$$ |  $$ |$$ /  $$ |         \$$  / $$ /  $$ |$$ |  $$ |$$ |  \__|      $$ |     $$ /  $$ |\$$$$$$\    $$ |    $$  __$$\ $$ /  $$ |$$ /  $$ |$$ |  $$ |
* $$ |      $$ |$$ |  $$ |$$ |  $$ |          $$ |  $$ |  $$ |$$ |  $$ |$$ |            $$ |     $$ |  $$ | \____$$\   $$ |$$\ $$ |  $$ |$$ |  $$ |$$ |  $$ |$$ |  $$ |
* $$ |      $$ |$$ |  $$ |\$$$$$$$ |          $$ |  \$$$$$$  |\$$$$$$  |$$ |            $$$$$$$$\\$$$$$$  |$$$$$$$  |  \$$$$  |$$$$$$$  |\$$$$$$  |\$$$$$$$ |\$$$$$$$ |
* \__|      \__|\__|  \__| \_______|          \__|   \______/  \______/ \__|            \________|\______/ \_______/    \____/ \_______/  \______/  \_______| \____$$ |
*                                                                                                                                                            $$\   $$ |
*                                                                                                                                                            \$$$$$$  |
*                                                                                                                                                            \______/
*/

pragma solidity ^0.8.7;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./SafeMath.sol";
import "./MerkleProof.sol";

interface IBayc {
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

contract LostBody is ERC721A, Ownable {
    using Strings for uint256;

    enum EPublicMintStatus {
        CLOSED,
        PUBLIC_MINT
    }

    struct reversemint {
        address reverseaddress;
        uint256 mintquantity;
    }

    string  public baseTokenURI;
    string  public defaultTokenURI;
    string  private _suffix = ".json";
    uint256 public maxSupply = 8624;
    uint256 public publicSalePrice = 0.0066 ether;
    address public proxyRegistryAddress = 0xa5409ec958C83C3f309868babACA7c86DCB077c1;
    address public Bayc = 0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D;

    mapping(uint256 => bool) public oldlostbodymint;
    mapping(uint256 => bool) public baycholderinfo;
    mapping(address => bool) public mintinfo;

    uint256[] public baycholdermintinfo;
    uint256 public baycHolderMintQuantity;
    uint256 public hasMintQuantityByPublic;
    uint256 public reverseMintQuantity;
    uint256 public totalFree=2000;

    EPublicMintStatus public publicMintStatus;

    constructor(
        string memory _baseTokenURI
    ) ERC721A("Find Your LostBody", "LOSTBODY") {
        baseTokenURI = _baseTokenURI;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Must from real wallet address");
        _;
    }

    function findlostbody_public(uint256 _quantity) external callerIsUser payable  {
        require(publicMintStatus==EPublicMintStatus.PUBLIC_MINT, "Public sale closed");
        require(hasMintQuantityByPublic + _quantity <= 7070, "Exceed supply");
        require(_quantity <= 4, "Max per TX reached.");
        require(!mintinfo[msg.sender], "The address mint has been completed");

        uint256 _remainFreeQuantity = 0;
        if (totalFree>hasMintQuantityByPublic){
            _remainFreeQuantity=totalFree-hasMintQuantityByPublic;
        }

        uint256 _needPayPrice = 0;
        if (_quantity>_remainFreeQuantity){
            _needPayPrice = (_quantity-_remainFreeQuantity)*publicSalePrice;
        }

        require(msg.value >= _needPayPrice, "Ether is not enough");
        hasMintQuantityByPublic+=_quantity;
        mintinfo[msg.sender]= true;
        _safeMint(msg.sender, _quantity);

    }


    function findlostbody_baycmint(uint256 _tokenid) external callerIsUser payable  {
        require(publicMintStatus==EPublicMintStatus.PUBLIC_MINT, "Baycholder sale closed");
        require(baycHolderMintQuantity <= 24 , "Exceed supply");
        require(!oldlostbodymint[_tokenid], "The bayc mint has been completed");
        address baycowner = IBayc(Bayc).ownerOf(_tokenid);
        require(baycowner==msg.sender, "This address is not the holder of this token");
        oldlostbodymint[_tokenid]= true;
        baycHolderMintQuantity += 1;
        baycholdermintinfo.push(_tokenid);
        _safeMint(msg.sender, 1);
    }


    function findlostbody_oldlostbodymint(uint256[] memory _tokenids) external callerIsUser payable  {
        require(publicMintStatus==EPublicMintStatus.PUBLIC_MINT, "Baycholder sale closed");
        for (uint i=0;i<_tokenids.length;i++){
            address oldowner = IBayc(0x655c6Af94919E0aeE453A35D1565244A52f33bf1).ownerOf(_tokenids[i]);
            require(!oldlostbodymint[_tokenids[i]], "The Old lostbody replacement has been completed");
            require(oldowner==msg.sender, "The address is not the holder of this token");
            oldlostbodymint[_tokenids[i]]= true;
        }
        uint _quantity = _tokenids.length;
        _safeMint(msg.sender, _quantity);
    }


    function findlostbody_reversemint(reversemint[] memory _reversemintinfos) external callerIsUser payable  {
        require(publicMintStatus==EPublicMintStatus.PUBLIC_MINT, "Baycholder sale closed");
        for (uint256 i=0;i<_reversemintinfos.length;i++){
            require(reverseMintQuantity+_reversemintinfos[i].mintquantity <= 340 , "Exceed supply");
            reverseMintQuantity+=_reversemintinfos[i].mintquantity;
            _safeMint(_reversemintinfos[i].reverseaddress, _reversemintinfos[i].mintquantity);
        }
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: Nonexistent token");
        string memory currentBaseURI = _baseURI();
        return
        bytes(currentBaseURI).length > 0 ? string(
            abi.encodePacked(
                currentBaseURI,
                tokenId.toString(),
                _suffix
            )
        ) : defaultTokenURI;
    }


    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string calldata _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function setDefaultURI(string calldata _defaultURI) external onlyOwner {
        defaultTokenURI = _defaultURI;
    }

    function setPublicMintStatus(uint256 status)external onlyOwner{
        publicMintStatus = EPublicMintStatus(status);
    }

    function setPublicPrice(uint256 mintprice)external onlyOwner{
        publicSalePrice = mintprice;
    }

    function setPublicFree(uint256 freemint)external onlyOwner{
        totalFree = freemint;
    }

    function withdrawMoney() external onlyOwner  {
        (bool success,) = msg.sender.call{value : address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function isApprovedForAll(address owner, address operator)
    public
    view
    override
    returns (bool)
    {
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        return proxyRegistryAddress == operator || address(proxyRegistry.proxies(owner)) == operator || super.isApprovedForAll(owner, operator);
    }

}

contract OwnableDelegateProxy {}

/**
 * Used to delegate ownership of a contract to another address, to save on unneeded transactions to approve contract use for users
 */
contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}
