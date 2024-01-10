// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;  

import "./ERC1155.sol";
import "./Strings.sol";
import "./Ownable.sol";

contract MiniMichAccessoryV2 is ERC1155, Ownable {
    address private miniMichContract=0xc08B0e21073f0641464B79FFCd1Bd99a4Dd79cE5;

    string private _metadataBaseURI;
    bool public saleLiveToggle=true;
    bool public freezeURI;

    uint256 public constant MAX_MINT = 5;
    uint256 public constant MAX_NFT = 500;
    uint256 public PRICE = 0.01 ether;
    
    mapping(uint256 => bool) public validAccessoryTypes;
    mapping(uint256 => uint256) public accessoryIndexes;

    address private _creators = 0x999eaa33BD1cE817B28459950E6DcD1dA14C411f;
 
    // ** MODIFIERS ** //
    // *************** //
    modifier saleLive() {
        require(saleLiveToggle == true, "Sale is not live yet");
        _;
    }

    modifier maxSupply(uint256 typeId, uint256 mintNum) {
       require(
            totalSupply(typeId) + mintNum <= MAX_NFT,
            "Sold Out"
        );
        _;
     }

    modifier correctPayment(uint256 mintPrice, uint256 numToMint) {
        require(
            msg.value >= mintPrice * numToMint,
            "Payment Failed"
        );
        _;
    }

    // ** CONSTRUCTOR ** //
    // *************** //
    constructor(string memory _baseURI) ERC1155(_baseURI) {
        _metadataBaseURI = _baseURI;
        validAccessoryTypes[0] = true;
        validAccessoryTypes[1] = true;
        validAccessoryTypes[2] = true;
        validAccessoryTypes[3] = true;
        validAccessoryTypes[4] = true;
        validAccessoryTypes[5] = true;
        validAccessoryTypes[6] = true;
        validAccessoryTypes[7] = true;
        validAccessoryTypes[8] = true;
        validAccessoryTypes[9] = true;
        validAccessoryTypes[10] = true;
        validAccessoryTypes[11] = true;
        validAccessoryTypes[12] = true;
        validAccessoryTypes[13] = true;
        validAccessoryTypes[14] = true;
        validAccessoryTypes[15] = true;
        validAccessoryTypes[16] = true;
        validAccessoryTypes[17] = true;
        validAccessoryTypes[18] = true;
        validAccessoryTypes[19] = true;
        emit SetBaseURI(_metadataBaseURI);
    }

    // ** MINT ** //
    // *************** //
    function publicMint(uint256 typeId, uint256 mintNum)
        external
        payable
        saleLive
        correctPayment(PRICE, mintNum)
        maxSupply(typeId, mintNum)
    {
        require(
            numberMinted(typeId, msg.sender) + mintNum <= MAX_MINT,
            "Reaches wallet limit."
        );
        _mint(_msgSender(), typeId, mintNum,"");
        accessoryIndexes[typeId]+=mintNum;
    }

    // ** ADMIN ** //
    // *********** //
    event SetBaseURI(string indexed _baseURI);
 
    function burnAccessoryForAddress(uint256 typeId, address burnTokenAddress)
        external
    {
        require(msg.sender == miniMichContract, "Invalid burner address");
        _burn(burnTokenAddress, typeId, 1);
    }

    function numberMinted(uint256 typeId, address owner) public view returns (uint256) {
        return balanceOf(owner, typeId);
    }

    function totalSupply(uint256 typeId) public view returns (uint256) {
        return accessoryIndexes[typeId];
    }

    function uri(uint256 typeId)
        public
        view                
        override
        returns (string memory)
    {
        require(
            validAccessoryTypes[typeId],
            "URI requested for invalid accessory type"
        );
        return
            bytes(_metadataBaseURI).length > 0
                ? string(abi.encodePacked(_metadataBaseURI, Strings.toString(typeId)))
                : _metadataBaseURI;
    }

    // ** OWNER ** //
    // *************** //
    function setMiniMichContractAddress(address miniMichContractAddress)
        external
        onlyOwner
    {
        miniMichContract = miniMichContractAddress;
    }

    function reserve(address[] calldata receivers, uint256 typeId, uint256 mintNum)
        external
        onlyOwner
        maxSupply(typeId, mintNum*receivers.length)
    {
        for (uint256 i = 0; i < receivers.length; i++) {
            _mint(receivers[i], typeId ,mintNum,"");
        }
        accessoryIndexes[typeId]+=mintNum*receivers.length;
    }

    function withdrawFunds() external onlyOwner {
        (bool success, ) = payable(_creators).call{value: address(this).balance}("");
        require(success, "Failed to send payment");
    }

    function setMetaURI(string calldata _URI) external onlyOwner {
        require(freezeURI == false, "Metadata is frozen");
        _metadataBaseURI = _URI;
        emit SetBaseURI(_metadataBaseURI);
    }

    function tglLive() external onlyOwner {
        saleLiveToggle = !saleLiveToggle;
    }

    function freezeAll() external onlyOwner {
        require(freezeURI == false, "Metadata is frozen");
        freezeURI = true;
    }

    function updatePrice(uint256 _price) external onlyOwner {
        PRICE = _price ;
    }
}