// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./AccessControl.sol";
import "./FineCoreInterface.sol";

interface FineNFTInterface {
    function mint(address to) external returns (uint);
    function mintBonus(address to, uint infiniteId) external returns (uint);
    function getArtistAddress() external view returns (address payable);
    function getAdditionalPayee() external view returns (address payable);
    function getAdditionalPayeePercentage() external view returns (uint256);
    function getTokenLimit() external view returns (uint256);
    function checkPool() external view returns (uint);
    function totalSupply() external view returns (uint256);
    function balanceOf(address owner) external view returns (uint256);
}

interface BasicNFTInterface {
    function ownerOf(uint256 tokenId) external view returns (address);
    function balanceOf(address owner) external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
}

enum SalePhase {
  Owner,
  PreSale,
  PublicSale
}

/// @custom:security-contact skyfly200@gmail.com
contract FineShop is AccessControl {
    using SafeMath for uint256;

    FineCoreInterface fineCore;
    mapping(uint => address) public projectOwner;
    mapping(uint => uint) public projectPremints;
    mapping(uint => uint) public projectPrice;
    mapping(uint => address) public projectCurrencyAddress;
    mapping(uint => string) public projectCurrencySymbol;
    mapping(uint => uint) public projectBulkMintCount;
    mapping(uint => bool) public projectLive;
    mapping(uint256 => bool) public contractFilterProject;
    mapping(address => mapping (uint256 => uint256)) public projectMintCounter;
    mapping(uint256 => uint256) public projectMintLimit;
    mapping(uint256 => SalePhase) public projectPhase;
    mapping(uint256 => mapping (address => uint8) ) public projectAllowList;
    mapping(uint256 => bool ) public infinitesAIWOW;
    mapping(uint256 => mapping (uint256 => address) ) public projectGateTokens;
    mapping(uint256 => uint256) public projectGateTokensCount;
    mapping(uint256 => mapping(uint256 => mapping(uint256 => bool)) ) public redeemed; // projectID, gateContractId, gateTokenId
    
    uint256[17] wowIds = [23,211,223,233,234,244,261,268,292,300,335,359,371,386,407,501,505];

    constructor(address _fineCoreAddresss) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        fineCore = FineCoreInterface(_fineCoreAddresss);
        for (uint256 i = 0; i < 17; i++) infinitesAIWOW[wowIds[i]] = true;
    }

    function stringComp(string memory str1, string memory str2) pure internal returns (bool) {
        return keccak256(abi.encodePacked(str1)) == keccak256(abi.encodePacked(str2));
    }

    // Admin Functions

    /**
     * @dev set the owner of a project
     * @param _projectId to set owner of
     * @param newOwner to set as owner
     */
    function setOwner(uint _projectId, address newOwner) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(projectOwner[_projectId] != newOwner, "can't be same owner");
        require(newOwner != address(0x0), "owner can't be zero address");
        projectOwner[_projectId] = newOwner;
    }

    /**
     * @dev push the project to live (locks setting and can premint)
     * @param _projectId to push live
     */
    function goLive(uint _projectId) external onlyRole(DEFAULT_ADMIN_ROLE) {
        bool ready = projectPrice[_projectId] > 0 && !stringComp(projectCurrencySymbol[_projectId], "");
        require(ready, "project not ready for live");
        projectLive[_projectId] = true;
    }
  
    /**
     * @dev set the mint limiter of a project
     * @param _projectId project to set mint limit of
     * @param _limit mint limit per address
     */
    function setProjectMintLimit(uint256 _projectId, uint8 _limit) public onlyRole(DEFAULT_ADMIN_ROLE) {
        projectMintLimit[_projectId] = _limit;
    }
  
    /**
     * @dev set the bulk mint count of a project
     * @param _projectId project to set mint limit of
     * @param _count of tokens mintable 
     */
    function setProjectBulkMintCount(uint256 _projectId, uint8 _count) public onlyRole(DEFAULT_ADMIN_ROLE) {
        projectBulkMintCount[_projectId] = _count;
    }

    /**
     * @dev set the contract mint filter
     * @param _projectId project to toggle the contract minting filter on
     */
    function toggleContractFilter(uint256 _projectId) public onlyRole(DEFAULT_ADMIN_ROLE) {
        contractFilterProject[_projectId]=!contractFilterProject[_projectId];
    }

    /**
     * @dev init the project
     * @param _projectId to set owner of
     * @param newOwner to set as owner
     * @param contractFilter switch to filter out minting via contract
     * @param _bulk amount for minitng multiple per tx
     * @param _limit mintable per address
     */
    function projectInit(
        uint _projectId,
        address newOwner,
        bool contractFilter,
        uint256 _bulk,
        uint256 _limit
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newOwner != address(0x0), "owner can't be zero address");
        projectOwner[_projectId] = newOwner;
        contractFilterProject[_projectId] = contractFilter;
        projectBulkMintCount[_projectId] = _bulk;
        projectMintLimit[_projectId] = _limit;
    }

    // Project Owner Functions

    modifier onlyOwner(uint _projectId) {
      require(msg.sender == projectOwner[_projectId], "only owner");
      _;
    }

    modifier isLive(uint _projectId) {
      require(projectLive[_projectId], "Project not yet live");
      _;
    }

    modifier notLive(uint _projectId) {
      require(!projectLive[_projectId], "Can't call once live");
      _;
    }

    /**
     * @dev set the price of a project
     * @param _projectId to set price of
     * @param price to set project to
     */
    function setPrice(uint _projectId, uint price) external onlyOwner(_projectId) notLive(_projectId) {
        projectPrice[_projectId] = price;
    }

    /**
     * @dev set the premints of a project
     * @param _projectId to set premints of
     * @param premints to set project to
     */
    function setPremints(uint _projectId, uint premints) external onlyOwner(_projectId) notLive(_projectId) {
        projectPremints[_projectId] = premints;
    }

    /**
     * @dev set the currency to ETH
     * @param _projectId to set currency of
     */
    function setCurrencyToETH(uint _projectId) external onlyOwner(_projectId) notLive(_projectId) {
        projectCurrencySymbol[_projectId] = "ETH";
        projectCurrencyAddress[_projectId] = address(0x0);
    }

    /**
     * @dev set the currency
     * @param _projectId to set currency of
     * @param _symbol of the currency
     * @param _contract address of the currency
     */
    function setCurrency(uint _projectId, string calldata _symbol, address _contract) external onlyOwner(_projectId) notLive(_projectId) {
        require(bytes(_symbol).length > 0, "Symbol must be provided");
        if (!stringComp(_symbol, "ETH"))
            require(_contract != address(0x0), "curency address cant be zero");
        projectCurrencySymbol[_projectId] = _symbol;
        projectCurrencyAddress[_projectId] = _contract;
    }

    /**
     * @dev owner may set project up in one call
     * @param _projectId to set up
     * @param _symbol of the currency
     * @param _contract address of the currency
     * @param _price of the project
     * @param _premints number available
     */
    function fullSetup(
            uint _projectId,
            string calldata _symbol,
            address _contract,
            uint256 _price,
            uint256 _premints
        ) external onlyOwner(_projectId) notLive(_projectId) {
            require(bytes(_symbol).length > 0, "Symbol must be provided");
            if (!stringComp(_symbol, "ETH"))
                require(_contract != address(0x0), "curency address cant be zero");
            projectCurrencySymbol[_projectId] = _symbol;
            projectCurrencyAddress[_projectId] = _contract;
            projectPrice[_projectId] = _price;
            projectPremints[_projectId] = _premints;
    }

    /**
     * @dev add an address to the allowlist
     * @param _projectId to set allowlist of
     * @param addresses to set allowlist counts for
     * @param numAllowedToMint number of mints to allow addresses
     */
    function setAllowList(uint _projectId, address[] calldata addresses, uint8 numAllowedToMint) external onlyOwner(_projectId) {
        for (uint256 i = 0; i < addresses.length; i++) {
            projectAllowList[_projectId][addresses[i]] = numAllowedToMint;
        }
    }

    /**
     * @dev set an NFT as a mint gating token
     * @param _projectId to set token for
     * @param addresses of token contracts
     */
    function setGateTokens(uint _projectId, address[] calldata addresses) external onlyOwner(_projectId) {
        projectGateTokensCount[_projectId] = addresses.length;
        for (uint256 i = 0; i < addresses.length; i++) {
            projectGateTokens[_projectId][i] = addresses[i];
        }
    }
    
    /**
     * @dev set mint phase of a project
     * @param _projectId to set phase of
     */
    function setPhase(uint _projectId, SalePhase phase) external onlyOwner(_projectId) isLive(_projectId) {
        projectPhase[_projectId] = phase;
    }

    // Sale Functions

    /**
     * @dev handle payment for a purchase
     * @param _projectId to handle payment for
     * @param count to purchase
     */
    function handlePayment(uint _projectId, uint count) internal {
        uint price = projectPrice[_projectId].mul(count);
        if (!stringComp(projectCurrencySymbol[_projectId], "ETH")){
            require(msg.value==0, "this project accepts a different currency and cannot accept ETH");
            require(IERC20(projectCurrencyAddress[_projectId]).allowance(msg.sender, address(this)) >= price, "Insufficient Funds Approved for TX");
            require(IERC20(projectCurrencyAddress[_projectId]).balanceOf(msg.sender) >= price, "Insufficient balance.");
            _splitFundsERC20(_projectId, count);
        } else {
            require(msg.value >= price, "Must send minimum value to mint!");
            _splitFundsETH(_projectId, count);
        }
    }

    /**
     * @dev split funds of payment made with ETH
     * @param _projectId to purchase
     * @param count number of tokens to purchase
     */
    function _splitFundsETH(uint256 _projectId, uint count) internal {
        if (msg.value > 0) {
            uint256 pricePerTokenInWei = projectPrice[_projectId];
            uint salePrice = pricePerTokenInWei.mul(count);
            uint256 refund = msg.value.sub(salePrice);
            if (refund > 0) {
                payable(msg.sender).transfer(refund);
            }
            uint256 platformAmount = salePrice.mul(fineCore.platformPercentage()).div(10000);
            if (platformAmount > 0) {
                fineCore.FINE_TREASURY().transfer(platformAmount);
            }
            FineNFTInterface nftContract = FineNFTInterface(fineCore.getProjectAddress(_projectId));
            uint256 additionalPayeeAmount = salePrice.mul(nftContract.getAdditionalPayeePercentage()).div(10000);
            if (additionalPayeeAmount > 0) {
                nftContract.getAdditionalPayee().transfer(additionalPayeeAmount);
            }
            uint256 creatorFunds = salePrice.sub(platformAmount).sub(additionalPayeeAmount);
            if (creatorFunds > 0) {
                nftContract.getArtistAddress().transfer(creatorFunds);
            }
        }
    }

    /**
     * @dev split funds of payment made with ERC20 tokens
     * @param _projectId to purchase
     * @param count number of tokens to purchase
     */
    function _splitFundsERC20(uint256 _projectId, uint count) internal {
        uint256 pricePerTokenInWei = projectPrice[_projectId];
        uint salePrice = pricePerTokenInWei.mul(count);
        uint256 platformAmount = salePrice.mul(fineCore.platformPercentage()).div(10000);
        if (platformAmount > 0) {
            IERC20(projectCurrencyAddress[_projectId]).transferFrom(msg.sender, fineCore.FINE_TREASURY(), platformAmount);
        }
        FineNFTInterface nftContract = FineNFTInterface(fineCore.getProjectAddress(_projectId));
        nftContract.getArtistAddress();
        uint256 additionalPayeeAmount = salePrice.mul(nftContract.getAdditionalPayeePercentage()).div(10000);
        if (additionalPayeeAmount > 0) {
            IERC20(projectCurrencyAddress[_projectId]).transferFrom(msg.sender, nftContract.getAdditionalPayee(), additionalPayeeAmount);
        }
        uint256 creatorFunds = salePrice.sub(platformAmount).sub(additionalPayeeAmount);
        if (creatorFunds > 0) {
            IERC20(projectCurrencyAddress[_projectId]).transferFrom(msg.sender, nftContract.getArtistAddress(), creatorFunds);
        }
    }

    // Minting Functions

    /**
     * @dev purchase tokens of a project and send to a specific address6
     * @param _projectId to purchase
     * @param to address to send token to
     * @param count number of tokens to purchase
     */
    function purchaseTo(uint _projectId, address to, uint count) internal isLive(_projectId) returns (string memory) {
        if (contractFilterProject[_projectId]) require(msg.sender == tx.origin, "No Contract Buys");
        // instantiate an interface with the projects NFT contract
        FineNFTInterface nftContract = FineNFTInterface(fineCore.getProjectAddress(_projectId));
        require(nftContract.checkPool() > 0, "Sold out");
        require(nftContract.checkPool() >= count, "Count excedes available");

        // Owner phase conditions
        if (projectPhase[_projectId] == SalePhase.Owner) {
            require(msg.sender == projectOwner[_projectId], "Only owner can mint now");
            require(count <= projectPremints[_projectId], "Excededs max premints");
            projectPremints[_projectId] -= count;
        } else {
            if (projectMintLimit[_projectId] > 0) {
                require(projectMintCounter[msg.sender][_projectId] < projectMintLimit[_projectId], "Reached minting limit");
                projectMintCounter[msg.sender][_projectId] += count;
            }
            // Presale phase conditions
            if (projectPhase[_projectId] == SalePhase.PreSale) {
                require(count <= projectAllowList[_projectId][msg.sender], "Exceeds allowlisted count");
                projectAllowList[_projectId][msg.sender] -= uint8(count);
            } else if (projectPhase[_projectId] == SalePhase.PublicSale) {
                if (projectBulkMintCount[_projectId] > 0)
                    require(count <= projectBulkMintCount[_projectId], "Count excedes bulk mint limit");
            }
            handlePayment(_projectId, count);
        }
        string memory idList;
        // mint number of tokens specified by count
        for (uint i = 0; i < count; i++) {
            uint tokenID = nftContract.mint(to);
            if (i == 0) idList = string(abi.encodePacked(tokenID));
            else idList = string(abi.encodePacked(idList, ",", tokenID));
        }

        return idList; // returns a list of ids of all tokens minted
    }

    /**
     * @dev purchase tokens of a project and send to a specific address (only holders of listed NFTs)
     * @param _projectId to purchase
     * @param to address to send token to
     * @param contractId of contract to lookup gate pass in the mapping
     * @param redeemId id of token to redeem gate pass for
     */
    function mintGated(uint _projectId, address to, uint8 contractId, uint256 redeemId) public payable isLive(_projectId) returns (string memory) {
        if (contractFilterProject[_projectId]) require(msg.sender == tx.origin, "No Contract Buys");
        // instantiate an interface with the projects NFT contract
        FineNFTInterface nftContract = FineNFTInterface(fineCore.getProjectAddress(_projectId));
        
        // Presale phase conditions
        require(projectPhase[_projectId] != SalePhase.Owner, "Must redeem after owner mint");
        BasicNFTInterface allowToken = BasicNFTInterface(projectGateTokens[_projectId][contractId]);
        require(nftContract.checkPool() > 0, "Sold out");
        require(
            allowToken.ownerOf(redeemId) == msg.sender || allowToken.ownerOf(redeemId) == to,
            "Only token owner can redeem pass");
        require(!redeemed[_projectId][contractId][redeemId], "already redeemed for ID");
        redeemed[_projectId][contractId][redeemId] = true;
        uint tokenId = nftContract.mint(to);
        // free bonus mints for coresponding Infinites AI tokens owned
        if (contractId == 0) nftContract.mintBonus(to, redeemId);
        // free mint for Infinites AI WOWs
        if (contractId != 0 || !infinitesAIWOW[redeemId]) handlePayment(_projectId, 1);
        else if (msg.value > 0) payable(msg.sender).transfer(msg.value);

        return string(abi.encodePacked(tokenId)); // returns a list of ids of all tokens minted
    }

    /**
     * @dev purchase tokens of a project
     * @param _projectId to purchase
     * @param count number of tokens to purchase
     */
    function buy(uint _projectId, uint count) external payable returns (string memory) {
        return purchaseTo(_projectId, msg.sender, count);
    }

    /**
     * @dev purchase tokens of a project for another address
     * @param _projectId to purchase
     * @param to recipients address
     * @param count number of tokens to purchase
     */
    function buyFor(uint _projectId, address to, uint count) external payable returns (string memory) {
        return purchaseTo(_projectId, to, count);
    }
}
