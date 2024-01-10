//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721Enumerable.sol";
import "./Math.sol";
import "./PaymentSplitter.sol";
import "./Allowlist.sol";
import "./ERC721A.sol";

contract WGMICollection is ERC721A, Ownable, Pausable, ReentrancyGuard, Allowlist, PaymentSplitter {
    uint private constant MAX_SUPPLY = 1000;
    uint private constant MAX_PER_TX = 20;
    uint private constant MAX_PRESALE_PER_TX = 3;
    // Metadata
    string internal _tokenURI;

    // Pricing and Withdraw 
    uint256 public ogPrice;
    uint256 public wlPrice;
    uint256 public publicPrice;

    constructor (
        string memory __tokenURI,
        uint _publicMintingFee,
        uint _ogMintingFee,
        uint _wlMintingFee,
        address[] memory _receivers,
        uint256[] memory _shares
    ) ERC721A("WGMICollection", "WGMI", MAX_PER_TX) PaymentSplitter(_receivers, _shares) Allowlist() {
        _tokenURI = __tokenURI;
        setPublicPrice(_publicMintingFee);
        setOgPrice(_ogMintingFee);
        setWlPrice(_wlMintingFee);
    }

    function preMint(uint amount, bytes32[] calldata _freeProof, bytes32[] calldata _ogProof, bytes32[] calldata _wlProof) external payable onlyAllowedPresale(_freeProof, _ogProof, _wlProof, amount) whenNotPaused nonReentrant {
        uint supply = totalSupply();
        uint amountTest = amount;
        require(amountTest < MAX_PRESALE_PER_TX + 1, "amount can't exceed 3");
        require(amountTest > 0, "amount too little");
        require(msg.sender != address(0), "empty address");
        require(supply + amountTest < MAX_SUPPLY + 2, "exceed max supply");

        // priority : FREE, OG, WL
        if (amount == 1) {
            if(!_freeMap[msg.sender] && isAllowedFree(_freeProof)) {
                setFreeMapSenderTrue();
            } else if (!_ogMap[msg.sender] && isAllowedOg(_ogProof)) {
                setOgMapSenderTrue();
            } else if (!_wlMap[msg.sender] && isAllowedWl(_wlProof)) {
                setWlMapSenderTrue();
            } else {
                revert("transaction exceed limit");
            }
        } else if (amount == 2) {
            if(!_freeMap[msg.sender] && !_ogMap[msg.sender] && isAllowedFree(_freeProof) && isAllowedOg(_ogProof)) {
                setFreeMapSenderTrue();
                setOgMapSenderTrue();
            } else if (!_freeMap[msg.sender] && !_wlMap[msg.sender]&& isAllowedFree(_freeProof) && isAllowedWl(_wlProof)) {
                setFreeMapSenderTrue();
                setWlMapSenderTrue();
            } else if (!_ogMap[msg.sender] && !_wlMap[msg.sender] && isAllowedOg(_ogProof) && isAllowedWl(_wlProof)) {
                setOgMapSenderTrue();
                setWlMapSenderTrue();
            } else {
                revert("transaction exceed limit");
            }
        } else {
            if(!_freeMap[msg.sender] && !_ogMap[msg.sender] && !_wlMap[msg.sender] && isAllowedFree(_freeProof) && isAllowedOg(_ogProof) && isAllowedWl(_wlProof)) {
                setFreeMapSenderTrue();
                setOgMapSenderTrue();
                setWlMapSenderTrue();
            } else {
                revert("transaction exceed limit");
            }
        }

        _safeMint(msg.sender, amountTest);

    }

     function publicMint(uint amount, bytes32[] calldata _proof) external payable onlyAllowedPublic(_proof) whenNotPaused nonReentrant {
        uint supply = totalSupply();
        require(amount < MAX_PER_TX + 1, "amount can't exceed 20");
        require(amount > 0, "amount too little");
        require(msg.value == publicPrice * amount, "insufficient fund");
        require(msg.sender != address(0), "empty address");
        require(supply + amount < MAX_SUPPLY + 2, "exceed max supply");

        _safeMint(msg.sender, amount);
    }
    

    function airdrop(address wallet, uint256 amount) external onlyOwner {
        uint256 supply = totalSupply();
        require(supply + amount <= MAX_SUPPLY + 2, "exceed max supply");
        
        for(uint256 i; i < amount; i++){
            _safeMint(wallet, supply + i );
        }
    }

    function owned(address owner) external view returns (uint256[] memory) {
        uint balance = balanceOf(owner);
        uint256[] memory tokenIds = new uint256[](balance);
        for(uint i=0;i<balance;i++){
            tokenIds[i] = tokenOfOwnerByIndex(owner, i);
        }
        return tokenIds;
    }

    // Pausable
    function setPause(bool pause) external onlyOwner {
        if(pause) {
            _pause();
        } else {
            _unpause();
        }
    }

    function setOgPrice(uint amount) public onlyOwner {
        ogPrice = amount;
    }

    function setWlPrice(uint amount) public onlyOwner {
        wlPrice = amount;
    }

    function setPublicPrice(uint amount) public onlyOwner {
        publicPrice = amount;
    }

    function claim() external {
        release(payable(msg.sender));
    }

    // Metadata
    function setTokenURI(string memory _uri) external onlyOwner {
        _tokenURI = _uri;
    }
    function baseTokenURI() external view returns (string memory) {
        return _tokenURI;
    }
    
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        return string(abi.encodePacked(
            _tokenURI,
            "/",
            Strings.toString(_tokenId),
            ".json"
        ));
    }

    function isAbleToFreeMint(bytes32[] calldata _proof) public view returns (bool) {
        return (!_freeMap[msg.sender] && isAllowedFree(_proof));
    }

    function isAbleToOgMint(bytes32[] calldata _proof) public view returns (bool) {
        return (!_ogMap[msg.sender] && isAllowedOg(_proof));
    }

    function isAbleToWlMint(bytes32[] calldata _proof) public view returns (bool) {
        return (!_wlMap[msg.sender] && isAllowedWl(_proof));
    }


    function setRequireAllowlist(bool value) public onlyOwner {
        _setRequireAllowlist(value);
    }
}
