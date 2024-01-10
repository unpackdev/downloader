//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ReentrancyGuard.sol";
import "./ECDSA.sol";
import "./Ownable.sol";
import "./ILaunchpadNFT.sol";

contract Launchpad is Ownable, ReentrancyGuard {
    event AddCampaign(address contractAddress, CampaignMode mode, address payeeAddress, uint256 price, uint256 maxSupply, uint256 listingTime, uint256 expirationTime, uint256 maxBatch, uint256 maxPerAddress, address validator);
    event UpdateCampaign(address contractAddress, CampaignMode mode, address payeeAddress, uint256 price, uint256 maxSupply, uint256 listingTime, uint256 expirationTime, uint256 maxBatch, uint256 maxPerAddress, address validator);
    event Mint(address indexed contractAddress, CampaignMode mode, address userAddress, address payeeAddress, uint256 size, uint256 price);

    enum CampaignMode {
        normal,
        whitelisted
    }
    struct Campaign {
        address contractAddress;
        address payeeAddress;
        uint256 price; // wei
        uint256 maxSupply;
        uint256 listingTime;
        uint256 expirationTime;
        uint256 maxBatch;
        uint256 maxPerAddress;
        address validator; // only for whitelisted
        uint256 minted;
    }

    mapping(address => Campaign) private _campaignsNormal;
    mapping(address => Campaign) private _campaignsWhitelisted;

    mapping(address => mapping(address => uint256)) private _mintPerAddressNormal;
    mapping(address => mapping(address => uint256)) private _mintPerAddressWhitelisted;

    function mintWhitelisted(
        address contractAddress,
        uint256 batchSize,
        bytes memory signature
    ) external payable nonReentrant {
        // basic check
        require(contractAddress != address(0), "contract address can't be empty");
        require(batchSize > 0, "batchSize must greater than 0");
        Campaign memory campaign = _campaignsWhitelisted[contractAddress];
        require(campaign.contractAddress != address(0), "contract not register");

        //  Check whitelist validator signature
        bytes32 messageHash = keccak256(abi.encodePacked(block.chainid, address(this), contractAddress, msg.sender));
        bytes32 proof = ECDSA.toEthSignedMessageHash(messageHash);
        require(ECDSA.recover(proof, signature) == campaign.validator, "whitelist verification failed");

        // activity check
        require(batchSize <= campaign.maxBatch, "reach max batch size");
        require(block.timestamp >= campaign.listingTime, "activity not start");
        require(block.timestamp < campaign.expirationTime, "activity ended");
        require(_mintPerAddressWhitelisted[contractAddress][msg.sender] + batchSize <= campaign.maxPerAddress, "reach max per address limit");
        require(campaign.minted + batchSize <= campaign.maxSupply, "reach campaign max supply");
        uint256 totalPrice = campaign.price * batchSize;
        require(msg.value >= totalPrice, "value not enough");

        // update record
        _mintPerAddressWhitelisted[contractAddress][msg.sender] = _mintPerAddressWhitelisted[contractAddress][msg.sender] + batchSize;

        // transfer token and mint
        payable(campaign.payeeAddress).transfer(totalPrice);
        ILaunchpadNFT(contractAddress).mintTo(msg.sender, batchSize);
        _campaignsWhitelisted[contractAddress].minted += batchSize;

        emit Mint(campaign.contractAddress, CampaignMode.whitelisted, msg.sender, campaign.payeeAddress, batchSize, campaign.price);
        // return
        uint256 valueLeft = msg.value - totalPrice;
        if (valueLeft > 0) {
            payable(_msgSender()).transfer(valueLeft);
        }
    }

    function mint(address contractAddress, uint256 batchSize) external payable nonReentrant {
        // basic check
        require(contractAddress != address(0), "contract address can't be empty");
        require(batchSize > 0, "batchSize must greater than 0");
        Campaign memory campaign = _campaignsNormal[contractAddress];
        require(campaign.contractAddress != address(0), "contract not register");

        // activity check
        require(batchSize <= campaign.maxBatch, "reach max batch size");
        require(block.timestamp >= campaign.listingTime, "activity not start");
        require(block.timestamp < campaign.expirationTime, "activity ended");
        require(_mintPerAddressNormal[contractAddress][msg.sender] + batchSize <= campaign.maxPerAddress, "reach max per address limit");
        require(campaign.minted + batchSize <= campaign.maxSupply, "reach campaign max supply");
        uint256 totalPrice = campaign.price * batchSize;
        require(msg.value >= totalPrice, "value not enough");

        // update record
        _mintPerAddressNormal[contractAddress][msg.sender] = _mintPerAddressNormal[contractAddress][msg.sender] + batchSize;

        // transfer token and mint
        payable(campaign.payeeAddress).transfer(totalPrice);
        ILaunchpadNFT(contractAddress).mintTo(msg.sender, batchSize);
        _campaignsNormal[contractAddress].minted += batchSize;

        emit Mint(campaign.contractAddress, CampaignMode.normal, msg.sender, campaign.payeeAddress, batchSize, campaign.price);
        // return
        uint256 valueLeft = msg.value - totalPrice;
        if (valueLeft > 0) {
            payable(_msgSender()).transfer(valueLeft);
        }
    }

    function getMintPerAddress(
        address contractAddress,
        CampaignMode mode,
        address userAddress
    ) external view returns (uint256 mintPerAddress) {
        Campaign memory campaign;
        if (mode == CampaignMode.normal) {
            campaign = _campaignsNormal[contractAddress];
            mintPerAddress = _mintPerAddressNormal[contractAddress][msg.sender];
        } else {
            campaign = _campaignsWhitelisted[contractAddress];
            mintPerAddress = _mintPerAddressWhitelisted[contractAddress][msg.sender];
        }

        require(campaign.contractAddress != address(0), "contract address invalid");
        require(userAddress != address(0), "user address invalid");
    }

    function getLaunchpadMaxSupply(address contractAddress, CampaignMode mode) external view returns (uint256) {
        if (mode == CampaignMode.normal) {
            return _campaignsNormal[contractAddress].maxSupply;
        } else {
            return _campaignsWhitelisted[contractAddress].maxSupply;
        }
    }

    function getLaunchpadSupply(address contractAddress, CampaignMode mode) external view returns (uint256) {
        if (mode == CampaignMode.normal) {
            return _campaignsNormal[contractAddress].minted;
        } else {
            return _campaignsWhitelisted[contractAddress].minted;
        }
    }

    function addCampaign(
        address contractAddress_,
        CampaignMode mode,
        address payeeAddress_,
        uint256 price_,
        uint256 listingTime_,
        uint256 expirationTime_,
        uint256 maxSupply_,
        uint256 maxBatch_,
        uint256 maxPerAddress_,
        address validator_
    ) external onlyOwner {
        require(contractAddress_ != address(0), "contract address can't be empty");
        require(expirationTime_ > listingTime_, "expiration time must above listing time");

        Campaign memory campaign;
        uint256 maxSupplyRest;
        if (mode == CampaignMode.normal) {
            campaign = _campaignsNormal[contractAddress_];
            maxSupplyRest = ILaunchpadNFT(contractAddress_).getMaxLaunchpadSupply() - _campaignsWhitelisted[contractAddress_].maxSupply;
        } else {
            campaign = _campaignsWhitelisted[contractAddress_];
            maxSupplyRest = ILaunchpadNFT(contractAddress_).getMaxLaunchpadSupply() - _campaignsNormal[contractAddress_].maxSupply;
            require(validator_ != address(0), "validator can't be empty");
        }

        require(campaign.contractAddress == address(0), "contract address already exist");

        require(payeeAddress_ != address(0), "payee address can't be empty");
        require(maxBatch_ > 0, "max batch invalid");
        require(maxPerAddress_ > 0, "max per address can't be 0");
        require(maxSupply_ <= maxSupplyRest, "max supply is exceeded");
        require(maxSupply_ > 0, "max supply can't be 0");

        emit AddCampaign(contractAddress_, mode, payeeAddress_, price_, maxSupply_, listingTime_, expirationTime_, maxBatch_, maxPerAddress_, validator_);
        campaign = Campaign(contractAddress_, payeeAddress_, price_, maxSupply_, listingTime_, expirationTime_, maxBatch_, maxPerAddress_, validator_, 0);
        if (mode == CampaignMode.normal) {
            _campaignsNormal[contractAddress_] = campaign;
        } else {
            _campaignsWhitelisted[contractAddress_] = campaign;
        }
    }

    function updateCampaign(
        address contractAddress_,
        CampaignMode mode,
        address payeeAddress_,
        uint256 price_,
        uint256 listingTime_,
        uint256 expirationTime_,
        uint256 maxSupply_,
        uint256 maxBatch_,
        uint256 maxPerAddress_,
        address validator_
    ) external onlyOwner {
        Campaign memory campaign;
        uint256 maxSupplyRest;
        require(contractAddress_ != address(0), "contract address can't be empty");
        require(expirationTime_ > listingTime_, "expiration time must above listing time");

        if (mode == CampaignMode.normal) {
            maxSupplyRest = ILaunchpadNFT(contractAddress_).getMaxLaunchpadSupply() - _campaignsWhitelisted[contractAddress_].maxSupply;
            campaign = _campaignsNormal[contractAddress_];
        } else {
            campaign = _campaignsWhitelisted[contractAddress_];
            maxSupplyRest = ILaunchpadNFT(contractAddress_).getMaxLaunchpadSupply() - _campaignsNormal[contractAddress_].maxSupply;
            require(validator_ != address(0), "validator can't be empty");
        }

        require(campaign.contractAddress != address(0), "contract address not exist");

        require(payeeAddress_ != address(0), "payee address can't be empty");
        require(maxBatch_ > 0, "max batch invalid");
        require(maxPerAddress_ > 0, "max per address can't be 0");
        require(maxSupply_ <= maxSupplyRest, "max supply is exceeded");
        require(maxSupply_ > 0, "max supply can't be 0");
        emit UpdateCampaign(contractAddress_, mode, payeeAddress_, price_, maxSupply_, listingTime_, expirationTime_, maxBatch_, maxPerAddress_, validator_);
        campaign = Campaign(contractAddress_, payeeAddress_, price_, maxSupply_, listingTime_, expirationTime_, maxBatch_, maxPerAddress_, validator_, campaign.minted);

        if (mode == CampaignMode.normal) {
            _campaignsNormal[contractAddress_] = campaign;
        } else {
            _campaignsWhitelisted[contractAddress_] = campaign;
        }
    }

    function getCampaign(address contractAddress, CampaignMode mode) external view returns (Campaign memory) {
        if (mode == CampaignMode.normal) {
            return _campaignsNormal[contractAddress];
        } else {
            return _campaignsWhitelisted[contractAddress];
        }
    }
}
