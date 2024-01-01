// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// import "./Seaport.sol";
import "./ConsiderationStructs.sol";
import "./OwnableUpgradeable.sol";
import "./ERC721Upgradeable.sol";
import "./IERC721Receiver.sol";
import "./ReentrancyGuardUpgradeable.sol";

enum ContractType {
    Starter,
    Trader,
    Pro
}

enum GasType {
    Normal,
    Speed,
    Ultra
}

interface ISeaport {
    function fulfillBasicOrder_efficient_6GL6yc(
        BasicOrderParameters calldata parameters
    ) external payable returns (bool fulfilled);
}

interface IConfigurationContract {
    function getSubscriptionPrice(
        ContractType contractType_
    ) external view returns (uint);

    function getSubscriptionDuration(
        ContractType contractType_
    ) external view returns (uint);

    function getSubscriptionConfigs(
        ContractType contractType_
    ) external view returns (uint);

    function getGas(GasType speed_) external view returns (uint);

    function getRefreshPrice(
        ContractType contractType_
    ) external view returns (uint);

    function getSubscriptionEnd(
        ContractType contractType_
    ) external view returns (uint);

    function getAddConfigPrice(
        ContractType contractType_
    ) external view returns (uint);

    function getTargetWallet() external view returns (address);

    function getBuyer(address buyer_) external view returns (bool);
}

contract TraderImplementation is
    OwnableUpgradeable,
    IERC721Receiver,
    ReentrancyGuardUpgradeable
{
    mapping(address erc721Address => mapping(uint tokenId => bool inStorage))
        public tokenInStorage;

    uint public aboEnd;
    uint public initialConfigs;
    uint public addedConfigs;
    ContractType public currentContractType;

    ISeaport public seaport;
    IConfigurationContract public configurationContract;

    event TokenStored(address indexed from, uint indexed tokenId);
    event Withdrawn(address indexed from, uint indexed tokenId);
    event EtherDeposited(address indexed sender, uint amount);
    event EtherWithdrawn(address indexed sender, uint amount);
    event NewSubscriptionCreated(
        uint256 newSubscriptionEnd,
        ContractType contractType,
        uint256 addedConfigs
    );
    event NewConfigAdded(uint256 addedConfigs);

    function initialize(
        address seaportAddress_,
        address configurationContractAddress_
    ) public initializer {
        __Ownable_init(msg.sender);
        __ReentrancyGuard_init();
        seaport = ISeaport(payable(seaportAddress_));
        configurationContract = IConfigurationContract(
            configurationContractAddress_
        );
    }

    function forwardOrder(
        BasicOrderParameters calldata orderParams_,
        uint amount_,
        address contract_,
        uint tokenId_,
        GasType speed_
    ) public payable {
        uint gas = configurationContract.getGas(speed_);
        require(address(this).balance >= amount_ + gas, "not enough balance");
        require(aboEnd > block.timestamp, "no active abo");
        require(
            configurationContract.getBuyer(msg.sender),
            "only buying wallets"
        );
        tokenInStorage[contract_][tokenId_] = true;

        seaport.fulfillBasicOrder_efficient_6GL6yc{value: amount_}(
            orderParams_
        );

        (bool success, ) = msg.sender.call{value: gas}("");
        require(success, "transfer failed");

        emit TokenStored(contract_, tokenId_);
    }

    function deposit() external payable {
        emit EtherDeposited(msg.sender, msg.value);
    }

    /**
     * @dev function to release the funds from the contract
     */
    function withdraw() public onlyOwner nonReentrant {
        uint balance = address(this).balance;
        (bool os, ) = payable(owner()).call{value: balance}("");
        require(os);
        emit EtherWithdrawn(msg.sender, balance);
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) public virtual override returns (bytes4) {
        tokenInStorage[msg.sender][tokenId] = true;
        emit TokenStored(msg.sender, tokenId);
        return this.onERC721Received.selector;
    }

    function manuallySetToken(
        address nftAddress_,
        uint256 tokenId_,
        bool tokenState
    ) public onlyOwner {
        tokenInStorage[nftAddress_][tokenId_] = tokenState;
    }

    function withdrawERC721(
        address nftAddress,
        uint256 tokenId
    ) public onlyOwner {
        require(
            tokenInStorage[nftAddress][tokenId],
            "token not deposited in vault"
        );
        IERC721 nftToken = IERC721(nftAddress);
        nftToken.safeTransferFrom(address(this), owner(), tokenId);
        tokenInStorage[nftAddress][tokenId] = false;
        emit Withdrawn(nftAddress, tokenId);
    }

    function newSubscription(
        ContractType contractType_,
        uint256 addedConfigs_
    ) public payable nonReentrant {
        require(aboEnd < block.timestamp, "can not refresh now");

        uint256 price = currentContractType != ContractType.Starter
            ? configurationContract.getRefreshPrice(contractType_)
            : configurationContract.getSubscriptionPrice(contractType_);

        uint256 configPrice = configurationContract.getAddConfigPrice(
            contractType_
        ) * addedConfigs_;

        require(msg.value >= price + configPrice, "not enough eth");
        aboEnd =
            block.timestamp +
            configurationContract.getSubscriptionDuration(contractType_) *
            1 days;
        initialConfigs = configurationContract.getSubscriptionConfigs(
            contractType_
        );
        addedConfigs = addedConfigs_;
        currentContractType = contractType_;
        address targetAddress = configurationContract.getTargetWallet();
        address payable payableTargetAddress = payable(targetAddress);
        payableTargetAddress.transfer(msg.value);

        emit NewSubscriptionCreated(aboEnd, contractType_, addedConfigs_);
    }

    function getConfigs() public view returns (uint) {
        if (aboEnd > block.timestamp) {
            return initialConfigs + addedConfigs;
        } else {
            return addedConfigs;
        }
    }

    function addConfig(uint256 amount_) public payable nonReentrant {
        require(msg.value >= calculatePrice(), "not enough eth");
        address targetAddress = configurationContract.getTargetWallet();
        address payable payableTargetAddress = payable(targetAddress);
        payableTargetAddress.transfer(msg.value);
        addedConfigs = addedConfigs + amount_;
        emit NewConfigAdded(addedConfigs);
    }

    function calculatePrice() public view returns (uint256 day) {
        require(block.timestamp < aboEnd, "need subscription first");
        day = (aboEnd - block.timestamp) / 1 days + 1;

        uint256 duration = configurationContract.getSubscriptionDuration(
            currentContractType
        );
        uint256 price = configurationContract.getAddConfigPrice(
            currentContractType
        );
        uint256 result = (day * price) / duration;
        return result;
    }
}
