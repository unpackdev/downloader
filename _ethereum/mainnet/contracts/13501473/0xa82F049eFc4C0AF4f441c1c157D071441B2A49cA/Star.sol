// SPDX-License-Identifier: MIT
// author: Giovanni Vignone
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";

abstract contract IMuttniks {
    function ownerOf(uint256 tokenId) public virtual view returns (address);
}

contract Star is Ownable, ERC721 {
    struct Wlist{
        uint256 approvedTokens;
        uint256 mintPriceWei;
    }
    using Counters for Counters.Counter;
    Counters.Counter public StarID;

    IMuttniks private MuttnikConnection;

    uint256 private maxSupply;

    address private contract_creator;

    bool public redeemable;

    bool public paused;

    bool public whiteListOn;

    bool public mintable;

    bool public metadataFrozen;

    string private storageLocation;

    uint256 public mintCost; 

    address private VerificationAdr;
    
    string private identifier;

    mapping(uint256 => string) private _tokenURIs;

    mapping(string => bool) private isCIDSet;

    mapping(uint256 => bool) public isMuttnikRedeemed;

    mapping(address => Wlist) public Whitelist;


    constructor(address verificationaccount, address adrMuttContract, string memory _identifier, string memory _gateway) ERC721("Muttniks Star", "STAR") {
        MuttnikConnection = IMuttniks(adrMuttContract);
        contract_creator = msg.sender;
        maxSupply = 3333;
        VerificationAdr = verificationaccount;
        mintCost = 60000000000000000;
        mintable = true;
        storageLocation = _gateway;
        redeemable = true;
        paused = true;
        identifier = _identifier;
    }



    // Owner only functions...

    function changeVerification(address verificationaddress) public onlyOwner {
        VerificationAdr = verificationaddress;
    }

    function batchChangeMetadata(uint256[] memory tokenIds, string[] memory _newTokenURIs) public onlyOwner {
        require(!metadataFrozen, "Metadata is frozen and unchangeable");
        for (uint256 i = 0; i < tokenIds.length; i++){
            require(_exists(tokenIds[i]), "ERC721Metadata: URI set of nonexistent token");
            _tokenURIs[tokenIds[i]] = _newTokenURIs[i];
        }
    }

    function flipSaleState() public onlyOwner {
        paused = !paused;
    }

    function changeMintprice(uint256 newMintCost) public onlyOwner {
        mintCost = newMintCost;
    }

    function setStorageLocation(string memory newLocation) public onlyOwner {
        require(!metadataFrozen, "Metadata is frozen and unchangeable");
        storageLocation = newLocation;
    }

    function changeSupply(uint256 newSupply) public onlyOwner {
        require(mintable, "Contract permanently decentralized");
        maxSupply = newSupply;
    }

    function flipRedeem() public onlyOwner {
        redeemable = !redeemable;
    }

    function changeWhitelistState() public onlyOwner {
        whiteListOn = !whiteListOn;
    }

    function addToWhitelist(address[] memory collectors, uint256[] memory tokensAllowed, uint256[] memory WLweicosts) public onlyOwner {
        require((collectors.length == tokensAllowed.length) && (tokensAllowed.length == WLweicosts.length));
        for (uint256 i = 0; i < tokensAllowed.length; i++) {
            Whitelist[collectors[i]].approvedTokens = tokensAllowed[i];
            Whitelist[collectors[i]].mintPriceWei = WLweicosts[i];
        }
    }

    function ownerBatchMint(string[] memory ipfsCIDs) public onlyOwner {
        require(mintable, "Contract is locked and permanently decentralized");
        require(StarID.current() + ipfsCIDs.length <= maxSupply, "Muttniks are sold out!");
        for (uint256 i = 0; i < ipfsCIDs.length; i++){
            require(isCIDSet[ipfsCIDs[i]] == false, "This Star already exists");
            uint256 uniquetokenID = StarID.current();
            _safeMint(msg.sender, uniquetokenID);
            _setTokenURI(uniquetokenID, ipfsCIDs[i]);
            StarID.increment();
            isCIDSet[ipfsCIDs[i]] = true;
        } 
    }

    function _withdraw(uint256 amountinwei, bool getall, address payable exportaddress) public onlyOwner returns (bool){
        if(getall == true){
            exportaddress.transfer(address(this).balance);
            return true;
        }
        require(amountinwei<address(this).balance,"Contract is not worth that much yet");
        exportaddress.transfer(amountinwei);
        return true;
    }

    function freezeMetdata() public onlyOwner {
        metadataFrozen = true;
        // On function call, metadata is locked and permenantly decentralized
    }

    function lockMint() public onlyOwner {
        mintable = false;
        // On function call, contract is permenantly unmintable
    }



    // Contract internal functions...

   function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    

    // Public signature functions...

    function checkValidData(string memory ipfsCID, bytes memory sig) public view returns(address){
       bytes32 message = keccak256(abi.encodePacked(ipfsCID, identifier));
       return (recoverSigner(message, sig));
   }

   function recoverSigner(bytes32 message, bytes memory sig) public pure returns (address)
     {
       uint8 v;
       bytes32 r;
       bytes32 s;
       (v, r, s) = splitSignature(sig);
       return ecrecover(message, v, r, s);
   }

   function splitSignature(bytes memory sig) public pure returns (uint8, bytes32, bytes32)
     {
       require(sig.length == 65);
       bytes32 r;
       bytes32 s;
       uint8 v;
       assembly {
           r := mload(add(sig, 32))
           s := mload(add(sig, 64))
           v := byte(0, mload(add(sig, 96)))
       }
       return (v, r, s);
   }



    // Public view state functions...

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "TokenURI query for nonexistent token");
        return string(abi.encodePacked(storageLocation, _tokenURIs[tokenId]));
    }

    function isStarMinted(string memory ipfsCID) public view returns (bool){
        return isCIDSet[ipfsCID];
    }



    //Public alter contract state functions...

    function mintStar(string memory ipfsCID, bytes memory signature, uint256[] memory muttnikTokenID)
        public payable
    {   
        require(mintable, "Contract is permanently decentralized");
        require(StarID.current() < maxSupply, "Muttniks are sold out!");
        if(whiteListOn){
            require(Whitelist[msg.sender].approvedTokens > 0 || ((((muttnikTokenID.length > 0) && MuttnikConnection.ownerOf(muttnikTokenID[0]) == msg.sender) && (isMuttnikRedeemed[muttnikTokenID[0]] == false) && redeemable)), "You are not entitled to mint Star yet");
        }
        require(!paused, "Contract is paused for minting");
        require(muttnikTokenID.length <= 1, "Parameters sent incorrectly");
        require(VerificationAdr == checkValidData(ipfsCID, signature), "Unauthentificated sender");
        require(isCIDSet[ipfsCID] == false, "This Star already exists");
        require(msg.sender != address(0) && msg.sender != address(this));
        uint256 uniquetokenID = StarID.current();
        if(redeemable){
            if(muttnikTokenID.length == 1){
                if(muttnikTokenID[0] <= 100 && muttnikTokenID[0] >= 0) {
                    require(msg.sender == MuttnikConnection.ownerOf(muttnikTokenID[0]), "You are not the owner of this 101 Foundation token");
                    require(isMuttnikRedeemed[muttnikTokenID[0]] == false, "You have already redeemed this Muttnik");
                    isMuttnikRedeemed[muttnikTokenID[0]] = true;
                    _safeMint(contract_creator, uniquetokenID);
                    _safeTransfer(contract_creator, msg.sender, uniquetokenID,"");
                    _setTokenURI(uniquetokenID, ipfsCID);
                    StarID.increment();
                    isCIDSet[ipfsCID] = true;
                    return;
                }
                else {
                    require(msg.sender == MuttnikConnection.ownerOf(muttnikTokenID[0]), "You are not the owner of this Muttnik token");
                    require(msg.value == mintCost/2, "Incorrect value sent: Should be half of mint");
                    require(isMuttnikRedeemed[muttnikTokenID[0]] == false, "You have already redeemed this Muttnik");
                    isMuttnikRedeemed[muttnikTokenID[0]] = true;
                    _safeMint(contract_creator, uniquetokenID);
                    _safeTransfer(contract_creator, msg.sender, uniquetokenID,"");
                    _setTokenURI(uniquetokenID, ipfsCID);
                    StarID.increment();
                    isCIDSet[ipfsCID] = true;
                    return;
                }
            }
        }
        if(whiteListOn){
            require(msg.value == Whitelist[msg.sender].mintPriceWei*10000000000000000);
            Whitelist[msg.sender].approvedTokens =  Whitelist[msg.sender].approvedTokens - 1;
        } else {
            require(msg.value >= mintCost, "Incorrect value sent");
        }
        _safeMint(contract_creator, uniquetokenID);
        _safeTransfer(contract_creator, msg.sender, uniquetokenID,"");
        _setTokenURI(uniquetokenID, ipfsCID);
        StarID.increment();
        isCIDSet[ipfsCID] = true;
    }
}