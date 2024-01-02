// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./NameWrapper.sol";
import "./INameWrapper.sol";
import "./IPriceOracle.sol";
import "./Ownable.sol";
import "./Strings.sol";

struct SaleConfig {
    address owner;
    uint88 price; // max value is 309,485,009 dollar
    bool isForSale;
    uint256 maxMint;
}

/**
 *
 * @title EnsVision Subdomain Storefront v4
 * @author hodl.esf.eth
 * @dev This contract allows users sell and mint subdomains.
 * @dev This contract is not upgradable.
 * @notice Developed by EnsVision.
 */
contract EnsSubdomainStorefront_v4 is Ownable {
    using Strings for uint256;
    event ConfigureSubdomain(uint256 indexed id, SaleConfig config);
    event DisableSales(address indexed owner, bool isDisabled);
    event PurchaseSubdomain(
        bytes32 indexed _ens,
        address _buyer,
        address _seller,
        string _label
    );

    mapping(uint256 => SaleConfig) public saleConfigs;
    mapping(address => bool) public isSalesDisabled;

    mapping(uint256 => uint256) public currentId;

    uint256 public visionPercentFee;

    NameWrapper public immutable nameWrapper;
    IPriceOracle public immutable priceOracle;

    constructor(
        NameWrapper _wrapper,
        IPriceOracle _oracle
    ) {
        nameWrapper = _wrapper;
        priceOracle = _oracle;
        visionPercentFee = 50;
        _transferOwnership(msg.sender);
    }

    /**
     * @notice configure sale settings for an ens
     * @param _ids ids of the domains to configure
     * @param _configs sale configs for the domains
     */
    function setUpDomains(
        uint256[] calldata _ids,
        SaleConfig[] calldata _configs
    ) public {
        for (uint256 i; i < _ids.length; ) {
            uint256 id = _ids[i];
            require(
                msg.sender == nameWrapper.ownerOf(id),
                "not owner of domain"
            );

            SaleConfig memory config = _configs[i];

            require(msg.sender == config.owner, "owner mismatch in config");

            saleConfigs[id] = config;
            emit ConfigureSubdomain(id, config);

            unchecked {
                ++i;
            }
        }
    }

    function setCurrentIdForDomain(uint256 _id, uint256 _currentId) public {
        require(msg.sender == nameWrapper.ownerOf(_id), "not owner of domain");
        currentId[_id] = _currentId;
    }

    function purchaseDomains(
        uint256[] calldata _ids,
        address[] calldata _mintTo,
        address _resolver,
        uint64[] calldata _duration
    ) public payable {
        uint256 accumulatedPrice;

        for (uint256 i; i < _ids.length; ) {
            {
                SaleConfig memory config = saleConfigs[_ids[i]];

                uint256 id;

                unchecked {
                    id = currentId[_ids[i]]++;
                }

                require(id < config.maxMint, "max mint reached");

                string memory label = id.toString();

                uint256 duration = type(uint64).max;
                {
                    address owner = nameWrapper.ownerOf(_ids[i]);
                    uint256 price;
                    // owner of the domain can always mint their own subdomains
                    if (owner != msg.sender) {
                        require(
                            (config.isForSale && !isSalesDisabled[owner]),
                            "domain not for sale"
                        );
                        // but users can't mint subdomains from legacy configs
                        require(owner == config.owner, "owner changed");

                        if (config.price > 0) {
                            price = getPrice(config);

                            uint256 commission = getCommission(price);
                            uint256 payment = price - commission;

                            // send the funds minus commission to the owner
                            payable(owner).call{value: payment, gas: 20_000}(
                                ""
                            );

                            accumulatedPrice += price;
                        }
                    }
                }

                uint256 subdomainId = uint256(
                    keccak256(
                        abi.encodePacked(
                            _ids[i],
                            keccak256(abi.encodePacked(label))
                        )
                    )
                );

                // check if the subdomain already exists
                require(
                    nameWrapper.ownerOf(subdomainId) == address(0),
                    "subdomain already exists"
                );

                mintSubdomain(
                    _ids[i],
                    label,
                    _mintTo[i],
                    _resolver,
                    config
                );

                emit PurchaseSubdomain(
                    bytes32(_ids[i]),
                    _mintTo[i],
                    config.owner,
                    label
                );
            }

            unchecked {
                ++i;
            }
        }

        require(msg.value >= accumulatedPrice, "not enough funds");

        uint256 excess = msg.value - accumulatedPrice;

        // send any excess funds back to the user
        if (excess > 0) {
            payable(msg.sender).call{value: excess}("");
        }
    }

    function purchaseDomain(
        uint256  _id,
        address  _mintTo,
        address _resolver,
        uint64  _duration
    ) public payable {


                SaleConfig memory config = saleConfigs[_id];

                uint256 id;

                unchecked {
                    id = currentId[_id]++;
                }

                require(id < config.maxMint, "max mint reached");

                string memory label = id.toString();
                uint256 price;
                uint256 duration = type(uint64).max;
                {
                    address owner = nameWrapper.ownerOf(_id);
                    
                    // owner of the domain can always mint their own subdomains
                    if (owner != msg.sender) {
                        require(
                            (config.isForSale && !isSalesDisabled[owner]),
                            "domain not for sale"
                        );
                        // but users can't mint subdomains from legacy configs
                        require(owner == config.owner, "owner changed");

                        if (config.price > 0) {
                            price = getPrice(config);

                            uint256 commission = getCommission(price);
                            uint256 payment = price - commission;

                            // send the funds minus commission to the owner
                            payable(owner).call{value: payment, gas: 20_000}(
                                ""
                            );
                        }
                    }
                }

                uint256 subdomainId = uint256(
                    keccak256(
                        abi.encodePacked(
                            _id,
                            keccak256(abi.encodePacked(label))
                        )
                    )
                );

                // check if the subdomain already exists
                require(
                    nameWrapper.ownerOf(subdomainId) == address(0),
                    "subdomain already exists"
                );

                mintSubdomain(
                    _id,
                    label,
                    _mintTo,
                    _resolver,
                    config
                );

                emit PurchaseSubdomain(
                    bytes32(_id),
                    _mintTo,
                    config.owner,
                    label
                );


        require(msg.value >= price, "not enough funds");

        uint256 excess = msg.value - price;

        // send any excess funds back to the user
        if (excess > 0) {
            payable(msg.sender).call{value: excess}("");
        }
    }

    function mintSubdomain(
        uint256 _parent,
        string memory _label,
        address _mintTo,
        address _resolver,
        SaleConfig memory _config
    ) internal {
        uint32 fuses = getFuses(_parent);

        nameWrapper.setSubnodeRecord(
            bytes32(_parent),
            _label,
            _mintTo,
            _resolver,
            0,
            fuses,
            type(uint64).max
        );
    }

    /**
     *
     * @dev update commission. 0 = 0%, 10 = 1%, 100 = 10%
     * @dev max commission is 10%
     */

    function updateVisionFee(uint256 _visionPercent) public onlyOwner {
        require(
            (_visionPercent <= 100 && _visionPercent > 5) ||
                _visionPercent == 0,
            "vision percent must 0, 0.5 - 10%"
        );

        visionPercentFee = _visionPercent;
    }

    function withdrawFunds() public onlyOwner {
        uint256 balance = address(this).balance;
        (bool result, ) = payable(msg.sender).call{value: balance}("");
        require(result, "transfer failed");
    }

    /**
     * @dev disable global sales for the calling address
     */
    function setGlobalSalesDisabled(bool _isDisabled) public {
        isSalesDisabled[msg.sender] = _isDisabled;

        emit DisableSales(msg.sender, _isDisabled);
    }

    function getPrice(
        SaleConfig memory _config
    ) private view returns (uint256) {
        uint256 dollarValue = priceOracle.getWeiValueOfDollar();
        uint256 fixedPrice = (dollarValue * _config.price) / 1 ether;

        return fixedPrice;
    }

    function getFuses(
        uint256 _parentId
    ) private view returns (uint32) {
        (, uint32 parentFuses, ) = nameWrapper.getData(_parentId);

        if (CANNOT_UNWRAP & parentFuses != 0) {
            return PARENT_CANNOT_CONTROL | CAN_EXTEND_EXPIRY;
        }

        return uint32(0);
    }

    function getConfigDataWithEthPrice(
        uint256 _parentId
    ) external view returns (SaleConfig memory, uint256) {
        //
        SaleConfig memory config = saleConfigs[_parentId];
        uint256 ethPrice = getPrice(config);
        return (config, ethPrice);
    }

    function getPrices(
        uint256[] calldata _ids
    ) external view returns (uint256[] memory) {
        uint256[] memory prices = new uint256[](_ids.length);

        for (uint256 i; i < _ids.length; ) {
            SaleConfig memory config = saleConfigs[_ids[i]];
            address owner = nameWrapper.ownerOf(_ids[i]);

            if (
                // if any of these conditions are true then
                // the subdomain is not for sale so set price to max
                owner != config.owner ||
                !config.isForSale ||
                isSalesDisabled[owner] ||
                !nameWrapper.isApprovedForAll(owner, address(this))
            ) {
                prices[i] = type(uint256).max;
            } else {
                prices[i] = getPrice(config);
            }

            unchecked {
                ++i;
            }
        }

        return prices;
    }

    function getCommission(uint256 _price) private view returns (uint256) {
        return (_price * visionPercentFee) / 1000;
    }
}
