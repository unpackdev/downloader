// SPDX-License-Identifier: MIT
/*///////////////////////////////////////////////////////////////////* *////////
/////////////////////////////////////////////////////////////////////, ,////////
/////////////////////////////////////////////////////////////////////  .////////
///////////////////////////////////////////////////////////////////    .////////
///////////////////////////////////////////////////////////////,       ,////////
/////////////////////////////////////////////////////////*             *////////
///////////////////////////////////////////////*,.            Oliver   /////////
////////////////////////////////////*,              Peter              /////////
/////////////////////////////.                             Chris      ,/////////
///////////////////////*                   Ismet                      //////////
////////////////////                               Danish            .//////////
/////////////////                   Ralf                             ///////////
//////////////.                               Erik                  ////////////
////////////                  Lorik                                ,////////////
//////////.                                                       ,/////////////
/////////                                                        ,//////////////
///////,               for                                      ////////////////
//////*                   Marie, Jonas, Julius, Maila,        ./////////////////
//////         */         Dicle, Manolya, Acelya,            ///////////////////
/////*      */.           Jalib and Max                    ,////////////////////
/////,   *//                                             .//////////////////////
/////*,//*             "the next generation"            ////////////////////////
////////                                             ,//////////////////////////
//////.                                           ./////////////////////////////
/////                                          .////////////////////////////////
////     .                                 .////////////////////////////////////
//,      ////                         */////////////////////////////////////////
/*      /////////*,.   ..,****//////////////////////////////////////////////////
/*    .,/////////////////////////////////////////////////////// envoverse.com */
// created by Ralf Schwoebel - https://www.envolabs.io/ - coding for the climate
// Art with purpose: Read up on our 5 year plan to improve the climate with NFTs

pragma solidity 0.8.12;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

contract envoContract is ERC721Enumerable, Ownable {
    using Strings for uint256;
    // ------------------------------------------------------------------------------
    address public contractCreator;
    mapping(address => uint256) public addressMintedBalance;
    // ------------------------------------------------------------------------------
    uint256 public constant MAX_ENVOS = 10000;
    uint256 public constant VIP_ENVOS = 555;
    uint256 public constant MAX_VIPWA = 1;         // Only 1 in VIP list in the first swing
    uint256 public constant MAX_VIPWAUNLOCK = 20;  // End phase of VIP list, if something is left
    uint256 public constant RES_ENVOS = 500;
    uint256 public ENVOSAVAIL = 9500;
    // ------------------------------------------------------------------------------
    uint256 public currentDonation = 0.5 ether;    // Before anything is starting - if someone "finds" contract by accident
    uint256 public startDonation = 0.399 ether;    // when the public auction starts
    uint256 public endDonation = 0.199 ether;      // when the auction ends
    uint256 public restingDonation = 0.333 ether;  // long term value - remember Issus
    uint256 public vipDate = 1646502955;           // Date and time (GMT) - will be: Saturday, March 5, 2022 5:55:55 PM
    uint256 public vipDateUnlock = 1646546155;     // Date and time (GMT) - will be: Sunday, March 6, 2022 5:55:55 AM - WL go crazy
    uint256 public vipDonation = 0.075 ether;      // VIP value before the auction starts
    uint256 public startDate = 1646675755;         // Start Auction Date and time (GMT) - will be: Monday, March 7, 2022 5:55:55 PM
    uint256 public endDate = 1646762155;           // End Auction Date and time (GMT) - will be: Tuesday, March 8, 2022 5:55:55 PM
    uint256 public vipCounter = 0;
    // ------------------------------------------------------------------------------
    string public baseTokenURI;
    string public baseExtension = ".json";
    bool public isActive = true;
    // ------------------------------------------------------------------------------
    bytes32 public VIPMerkleRoot;
    bytes32[] VIPMerkleProofArr;
    address envolabsWallet = 0x5C8175298d3bdC2B5168773A4ac72d81f5122fF1;   // Secured founders wallet,
    address pumaWallet = 0x4B26BdF68Ac9Abfb19F6146313428E7F8B6041F4;       // thank you,
    address ponderwareWallet = 0xD342a4F0397B4268e6adce89b9B88C746AFA85Ee; // for the support!
    address nineWallet = 0x8c0d2B62F133Db265EC8554282eE60EcA0Fd5a9E;       // 9x9x9, thanks, buddy!

    event mintedEnvo(uint256 indexed id);

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI
    ) ERC721(_name, _symbol) {
        contractCreator = msg.sender;
        setBaseURI(_initBaseURI);
        mint(envolabsWallet, 14);     // mint the first 16 to the founders envolabs wallet, supporters and honorary
        mint(pumaWallet, 2);          // Thank you for the support, PUMA.eth!
        mint(ponderwareWallet, 4);    // Thank you for the support, mooncats!
        mint(nineWallet, 1);          // Thank you for the support, 9x9x9!
    }

    // internal return the base URI
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    // ------------------------------------------------------------------------------------------------
    // public mint function - mints only to sender!
    function mint(address _to, uint256 _mintAmount) public payable {
        uint256 supply = totalSupply();
        currentDonation = calcValue();
        if(msg.sender != contractCreator) {
            require(isActive, "Contract paused!");
        }
        require(_mintAmount > 0, "We can not mint zero...");
        require(supply + _mintAmount <= ENVOSAVAIL, "Supply exhausted, sorry we are sold out!");
        if(msg.sender != contractCreator) {
            require(msg.value >= currentDonation * _mintAmount, "You have not sent enough currency.");
        }
        for (uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(_to, supply + i);
            emit mintedEnvo(supply + i);
        }
    }
    // ------------------------------------------------------------------------------------------------
    // VIP Miniting functions (aka Whitelist) - used via envoverse.com website - mints only one!
    function VIPmint(bytes32[] calldata merkleArr) public payable {
        uint256 supply = totalSupply();
        uint256 currentTime = block.timestamp;

        require(currentTime >= vipDate, "VIP cycle has not started yet!");
        require(currentTime <= startDate, "VIP cycle has ended, all ENVOS are now in the same set!");
        // set the proof array for the VIPlist for whitelisters
        VIPMerkleProofArr = merkleArr;
        require(
            MerkleProof.verify(
                VIPMerkleProofArr,
                VIPMerkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            ), "Address does not exist in VIP list"
        );
        require(vipCounter < VIP_ENVOS, "VIP list exhausted");
        require(supply + 1 <= ENVOSAVAIL, "max NFT limit exceeded");

        if(currentTime < vipDateUnlock) {
            require(balanceOf(msg.sender) <= MAX_VIPWA, "You have reached your maximum allowance of Envos.");
        } else {
            require(balanceOf(msg.sender) <= MAX_VIPWAUNLOCK, "You have reached your maximum allowance of Envos.");
        }

        require(msg.value >= vipDonation, "You have not sent enough value.");

        _safeMint(msg.sender, supply + 1);
        vipCounter = vipCounter + 1;
        emit mintedEnvo(supply + 1);
    }
    // --------------------------------------------------------------------------------------
    function setVIPMerkleRoot(bytes32 merkleRoot) public onlyOwner {
        VIPMerkleRoot = merkleRoot;
    }
    function setMerkleProof(bytes32[] calldata merkleArr) public onlyOwner {
        VIPMerkleProofArr = merkleArr;
    }
    // ------------------------------------------------------------------------------------------------
    // ------------------------------------------------------------------------------------------------
    // Dutch auction in hourly steps (optional, set to same values, if disabled)
    function calcValue() internal view returns (uint256 nowValue) {
        // local vars to calc time frame and VIP values
        uint256 currentTime = block.timestamp;
        uint256 tickerSteps = endDate - startDate;
        uint256 currentSteps;
        uint256 daValueSteps;

        // check config
        require(isActive, "Donations are paused at the moment!");

        // No VIP sale yet nor did auction start!
        // ----------------------------------- regular value calc
        if(currentTime < startDate) {
            return currentDonation;
        }

        // there is only one value at the end of the auction = final
        if(currentTime > endDate) {
            return restingDonation;
        } else {
            // calc the hourly dropping dutch value
            daValueSteps = (startDonation - endDonation) / tickerSteps;
            currentSteps = currentTime - startDate;
            return startDonation - (daValueSteps * currentSteps);
        }
    }
    // ------------------------------------------------------------------------------------------------
    // ------------------------------------------------------------------------------------------------
    // - useful other tools
    // -
    function showVIPproof() public view returns (bytes32[] memory) {
        return VIPMerkleProofArr;
    }
    // -
    function giveRightNumber(uint256 myNumber) public pure returns (uint) {
        return myNumber % 10;
    }
    // -
    function showCurrentDonation() public view returns (uint256) {
        return calcValue();
    }
    // -
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseTokenURI = _newBaseURI;
    }
    // show current blockchain time
    function showBCtime() public view returns (uint256) {
        return block.timestamp;
    }
    // give complete tokenURI back, if base is set
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, giveRightNumber(tokenId).toString(), "/envo", tokenId.toString(), baseExtension)) : "";
    }
    //---------------------------------------------------------------------------------------
    //---------------------------------------------------------------------------------------
    // config functions, if needed for updating the settings by creator
    function changeReserved(uint256 newTotal) public onlyOwner {
        ENVOSAVAIL = newTotal;
    }
    function setStartDonation(uint256 newStartDonation) public onlyOwner {
        startDonation = newStartDonation;
    }
    function setEndDonation(uint256 newEndDonation) public onlyOwner {
        endDonation = newEndDonation;
    }
    function setStartDate(uint256 newStartTimestamp) public onlyOwner {
        startDate = newStartTimestamp;
    }
    function setEndDate(uint256 newEndTimestamp) public onlyOwner {
        endDate = newEndTimestamp;
    }
    function setVIPDate(uint256 newVIPTimestamp) public onlyOwner {
        vipDate = newVIPTimestamp;
    }
    function setVIPUnlockDate(uint256 newVIPTimestamp) public onlyOwner {
        vipDateUnlock = newVIPTimestamp;
    }
    function setVIPDonation(uint256 newVIPDonation) public onlyOwner {
        vipDonation = newVIPDonation;
    }
    function setRestingDonation(uint256 newRestingDonation) public onlyOwner {
        restingDonation = newRestingDonation;
    }
    // ----------------------------------------------------------------- WITHDRAW
    function withdraw() public onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }
    function withdrawAllToAddress(address addr) public onlyOwner {
        require(payable(addr).send(address(this).balance));
    }
}