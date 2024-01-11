// SPDX-License-Identifier: MIT
//
//
//
//                           ,/(##(/,.                                                      .,/####(*.
//                    (&&&&&&&&&&&&&&&&&&&&(                   &&&&&&&&&             .%&&&&&&&&&&&&&&&&&&&&/
//                 %&&&&&&&&&&&&&&&&&&&&&&&&&&#             ,&&&&&&&&&&&          /&&&&&&&&&&&&&&&&&&&&&&&&&&&&.
//               .&&&&&&&&&&&&&&%&&&&&&&&&&&&&&&,     (&&&&&&&&&&&&&&&&&        &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&*
//               &&&&&&&&&#            .&&&&&&&&&/    (&&&&&&&&&&&&&&&&&      #&&&&&&&&&&%.            ,%&&&&&&&&&&.
//              .&&&&&&&&&#              .%%%%%%%%    /%#(/.   %&&&&&&&&     #&&&&&&&&&*                  #&&&&&&&&&.
//               *&&&&&&&&&&&&&&%(,.                           #&&&&&&&&    /&&&&&&&&&.                    .&&&&&&&&&
//                 %&&&&&&&&&&&&&&&&&&&&&&#*                   #&&&&&&&&    &&&&&&&&&*
//                    .%&&&&&&&&&&&&&&&&&&&&&&&%               #&&&&&&&&    &&&&&&&&&,
//                            ,*%&&&&&&&&&&&&&&&&&*            #&&&&&&&&    &&&&&&&&&*
//             ********                .#&&&&&&&&&&,           #&&&&&&&&    ,&&&&&&&&&,                    (&&&&&&&&&.
//             &&&&&&&&%                  ,&&&&&&&&&           #&&&&&&&&     (&&&&&&&&&(                 /&&&&&&&&&&
//             /&&&&&&&&&&.              #&&&&&&&&&*           #&&&&&&&&      (&&&&&&&&&&&*          .%&&&&&&&&&&&&
//              ,&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&(            #&&&&&&&&        %&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&,
//                ,&&&&&&&&&&&&&&&&&&&&&&&&&&&&&#              #&&&&&&&&          *&&&&&&&&&&&&&&&&&&&&&&&&&&&%
//                    /&&&&&&&&&&&&&&&&&&&&&&,                 #&&&&&&&&              (&&&&&&&&&&&&&&&&&&&&*
//                            .,***,.                                                         ,,,,,,
//
//

pragma solidity ^0.8.0;
pragma abicoder v2;

import "./Context.sol";
import "./SafeMath.sol";
import "./IERC165.sol";
import "./ERC165.sol";
import "./Mint721AValidator.sol";
import "./ERC721AURI.sol";
import "./LibERC721AMint.sol";
import "./Royalty.sol";
import "./ERC721AEnumerableMinimal.sol";
import "./OwnablePausable.sol";
import "./console.sol";

contract ERC721ARareCirclesMinimal is
    Context,
    OwnablePausable,
    ERC721AMinimal,
    Mint721AValidator,
    ERC721AURI,
    ERC721AEnumerableMinimal,
    Royalty
{
    using SafeMath for uint256;

    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;
    bytes4 private constant _INTERFACE_ID_ERC721A = 0x80ac58cd;
    bytes4 private constant _INTERFACE_ID_ERC721A_METADATA = 0x5b5e139f;
    bytes4 private constant _INTERFACE_ID_ERC721A_ENUMERABLE = 0x780e9d63;
    bytes4 private constant _INTERFACE_ID_ROYALTIES = 0x2a55205a; /// bytes4(keccak256("royaltyInfo(uint256,uint256)")) == 0x2a55205a

    // Max Supply
    uint256 private _maxSupply;

    // RareCircles Treasury
    address private _RCTreasury;

    // Merchant Treasury
    address private _merchantTreasury;

    event CreateERC721ARareCircles(address indexed owner, string name, string symbol);
    event Payout(address indexed to, uint256 amount);
    event Fee(address indexed to, uint256 amount);
    event Mint(uint256 amount, address indexed to);
    event BaseURI(string uri);
    event PlaceholderHolderURI(string uri);
    event MerchantTreasury(address treasury);
    event RarecirclesTreasury(address treasury);
    event MaxSupply(uint256 maxSupply);
    event Name(string name);
    event Symbol(string symbol);

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseURI,
        string memory _placeholderURI,
        uint256 maxSupply_
    ) Mint721AValidator("Rarecircles", "1") ERC721AMinimal(_name, _symbol) {
        _setBaseURI(_baseURI);
        _setPlaceholderURI(_placeholderURI);
        _maxSupply = maxSupply_;
        emit CreateERC721ARareCircles(_msgSender(), _name, _symbol);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721AMinimal, ERC721AEnumerableMinimal)
        returns (bool)
    {
        return
            interfaceId == _INTERFACE_ID_ERC165 ||
            interfaceId == _INTERFACE_ID_ERC721A ||
            interfaceId == _INTERFACE_ID_ERC721A_METADATA ||
            interfaceId == _INTERFACE_ID_ERC721A_ENUMERABLE ||
            interfaceId == _INTERFACE_ID_ROYALTIES;
    }

    function mintAndTransfer(LibERC721AMint.Mint721AData memory data)
        public
        payable
    {
        //require(msg.value > 0, "ERC721: call requires an amount of ETH");
        require(
            data.fee <= msg.value,
            "ERC721: application fee must be less then or equal to ETH sent"
        );
        // Mint Limit
        uint256 existingAmount = balanceOf(msg.sender);
        if (data.limit > 0) {
            require(existingAmount + data.amount <= data.limit, "ERC721: can't exceed the limit");
        }

        
        // We make sure that this has been signed by the contract owner
        bytes32 hash = LibERC721AMint.hash(data);
        validate(owner(), hash, data.signature);
        require(msg.value == data.cost, "ERC721: insufficient amount");
        // this is th perform calling mint, it may or may not match data.recipient
        address sender = _msgSender();
        require(
            sender == data.recipient ||
                isApprovedForAll(data.recipient, sender),
            "ERC721: transfer caller is not owner nor approved"
        );
        _mintTo(data.amount, sender);
        uint256 payout = msg.value - data.fee;
        if (payout > 0 && _merchantTreasury != address(0)) {
            payable(_merchantTreasury).transfer(payout);
            emit Payout(_merchantTreasury, payout);
        }
        if (data.fee > 0 && _RCTreasury != address(0)) {
            payable(_RCTreasury).transfer(data.fee);
            emit Fee(_RCTreasury, data.fee);
        }
    }

    function mintTo(uint256 _amount, address _to) public onlyOwner {
        _mintTo(_amount, _to);
    }

    function setTokenURI(uint256 _tokenId, string memory _tokenURI)
        public
        onlyOwner
    {
        return ERC721AURI._setTokenURI(_tokenId, _tokenURI);
    }

    function _mintTo(uint256 _amount, address _to) internal whenNotPaused {
        // Max Supply
        if (_maxSupply > 0) {
            require(totalSupply() + _amount <= _maxSupply, "ERC721: can't exceed max supply");
        }
        _safeMint(_to, _amount);
        emit Mint(_amount, _to);
    }

    // function updateAccount(
    //     uint256 _id,
    //     address _from,
    //     address _to
    // ) external {
    //     require(_msgSender() == _from, "not allowed");
    //     super._updateAccount(_id, _from, _to);
    // }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721AMinimal, ERC721AURI)
        returns (string memory)
    {
        return ERC721AURI.tokenURI(tokenId);
    }

    function tokenOfOwnerByIndex(address owner, uint256 index)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return super.tokenOfOwnerByIndex(owner, index);
    }

    function tokensOfOwner(address owner)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        return super.tokensOfOwner(owner);
    }

    function totalSupply()
        public
        view
        virtual
        override(ERC721AEnumerableMinimal, ERC721AMinimal)
        returns (uint256)
    {
        return ERC721AEnumerableMinimal.totalSupply();
    }

    function tokenByIndex(uint256 index)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return super.tokenByIndex(index);
    }

    function setBaseTokenURI(string memory baseTokenURI_) public onlyOwner {
        _setBaseURI(baseTokenURI_);
        emit BaseURI(baseTokenURI_);
    }

    function baseTokenURI() public view returns (string memory) {
        return super.baseURI();
    }

    function setPlaceholderURI(string memory placeholderURI_) public onlyOwner {
        _setPlaceholderURI(placeholderURI_);
        emit PlaceholderHolderURI(placeholderURI_);
    }

    function placholderURI() public view returns (string memory) {
        return super.placeholderURI();
    }

    function setMerchantTreasury(address treasury_) public onlyOwner {
        _merchantTreasury = treasury_;
        emit MerchantTreasury(treasury_);
    }

    function merchantTreasury() public view returns (address) {
        return _merchantTreasury;
    }

    function setRCTreasury(address treasury_) public onlyOwner {
        _RCTreasury = treasury_;
        emit RarecirclesTreasury(treasury_);
    }

    function RCTreasury() public view returns (address) {
        return _RCTreasury;
    }

    function setRoyalty(address creator_, uint256 amount_) public onlyOwner {
        _saveRoyalty(LibPart.Part(creator_, amount_));
    }

    function setName(string memory name_) public onlyOwner {
        _setName(name_);
        emit Name(name_);
    }

    function setSymbol(string memory symbol_) public onlyOwner {
        _setSymbol(symbol_);
        emit Symbol(symbol_);
    }

    function setMaxSupply(uint256 maxSupply_) public onlyOwner {
        _maxSupply = maxSupply_;
        emit MaxSupply(maxSupply_);
    }

    function maxSupply() public view returns (uint256) {
        return _maxSupply;
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal override(ERC721AMinimal, ERC721AEnumerableMinimal) {
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }
}
