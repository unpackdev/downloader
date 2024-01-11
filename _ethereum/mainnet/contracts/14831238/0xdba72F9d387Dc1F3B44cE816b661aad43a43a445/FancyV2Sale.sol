// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

import "./AccessControlEnumerable.sol";
import "./SafeERC20.sol";
import "./IFancy721.sol";
import "./IHoneyToken.sol";
import "./IFancyBears.sol";
import "./IHive.sol";
import "./tag.sol";

contract FancyV2Sale is AccessControlEnumerable {
    
    enum SaleState {
        Off,
        Active
    }

    using SafeERC20 for IHoneyToken;

    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    IFancy721 public fancy721Contract;
    IFancyBears public fancyBearsContract;
    IHoneyToken public honeyTokenContract;
    IHive public hiveContract;

    SaleState public saleState;
    uint256 public price;
    uint256 public honeyReward;

    constructor(
        IFancy721 _fancy721Contract,
        IFancyBears _fancyBearsContract,
        IHoneyToken _honeyTokenContract,
        IHive _hiveContract
    ) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        fancy721Contract = _fancy721Contract;
        fancyBearsContract = _fancyBearsContract;
        honeyTokenContract = _honeyTokenContract;
        hiveContract = _hiveContract;

        saleState = SaleState.Off;
    }

    function mint(uint256[] calldata _referenceTokenIds) public payable {
        require(saleState == SaleState.Active, "mint: sale must be active");

        uint256 numTokens = _referenceTokenIds.length;

        require(
            fancyBearsContract.balanceOf(msg.sender) > 0
                ? msg.value >= (numTokens * price) / 2
                : msg.value >= (numTokens * price),
            "mint: incorrect value"
        );

        fancy721Contract.safeMint(msg.sender, _referenceTokenIds);
        uint256[] memory amounts = new uint256[](numTokens);
        address[] memory collections = new address[](numTokens);
        for (uint256 i = 0; i < numTokens; i++) {
            collections[i] = address(fancy721Contract);
            amounts[i] = honeyReward;
        }
        hiveContract.depositHoneyToTokenIdsOfCollections(
            collections,
            _referenceTokenIds,
            amounts
        );
    }

    function reserve(
        address[] calldata _to,
        uint256[][] calldata _referenceTokenIds
    ) public onlyRole(MANAGER_ROLE) {
        require(
            _to.length == _referenceTokenIds.length,
            "reserve: arrays must match in length"
        );

        uint256 numTokens;

        for (uint256 i = 0; i < _referenceTokenIds.length; i++) {
            numTokens += _referenceTokenIds[i].length;
        }

        uint256 index;

        uint256[] memory amounts = new uint256[](numTokens);
        address[] memory collections = new address[](numTokens);
        uint256[] memory tokenIds = new uint256[](numTokens);

        for (uint256 i = 0; i < _to.length; i++) {
            fancy721Contract.safeMint(_to[i], _referenceTokenIds[i]);

            for (uint256 j = 0; j < _referenceTokenIds[i].length; j++) {
                collections[index] = address(fancy721Contract);
                amounts[index] = honeyReward;
                tokenIds[index] = _referenceTokenIds[i][j];
                index++;
            }
        }
        hiveContract.depositHoneyToTokenIdsOfCollections(
            collections,
            tokenIds,
            amounts
        );
    }

    function approveHiveToPullHoney(uint256 _amount)
        public
        onlyRole(MANAGER_ROLE)
    {
        honeyTokenContract.approve(address(hiveContract), _amount);
    }

    function withdrawETHBalance(address _address)
        public
        onlyRole(MANAGER_ROLE)
    {
        uint256 balance = address(this).balance;
        require(payable(_address).send(balance));
    }

    function withdrawHoneyBalance(address _address)
        public
        onlyRole(MANAGER_ROLE)
    {
        require(
            saleState == SaleState.Off,
            "withdrawHoneyBalance: claim must be off"
        );
        honeyTokenContract.safeTransfer(
            _address,
            honeyTokenContract.balanceOf(address(this))
        );
    }

    function setClaimState(SaleState _claimState)
        public
        onlyRole(MANAGER_ROLE)
    {
        saleState = _claimState;
    }

    function updatePrice(uint256 _price) public onlyRole(MANAGER_ROLE) {
        require(saleState == SaleState.Off, "updatePrice: claim must be off");
        price = _price;
    }

    function updateHoneyReward(uint256 _honeyReward)
        public
        onlyRole(MANAGER_ROLE)
    {
        require(saleState == SaleState.Off, "updateHoneyReward: claim must be off");
        honeyReward = _honeyReward;
    }
}
