// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./ERC20.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

contract BITFToken is ERC20, Ownable {
    using SafeERC20 for IERC20;

    uint256 public constant BITFOREX_WORTH = 15000;

    address public saleContractAddress;
    address public marketing;
    address public founderPool;
    address public ecoSystem;
    address public advisor;
    address public searchEngine;
    address public bitForex;
    address public VCPool;
    uint8 public airDropEnable;

    mapping(address => uint256) public airdropList;

    constructor(
        address _saleContractAddr,
        address _marketing,
        address _founder,
        address _ecoSystem,
        address _searchEngine,
        address _advisor,
        address _VCPool
    ) ERC20("BitFinder", "BITF") {
        saleContractAddress = _saleContractAddr;
        marketing = _marketing;
        founderPool = _founder;
        ecoSystem = _ecoSystem;
        advisor = _advisor;
        searchEngine = _searchEngine;
        VCPool = _VCPool;
        // ICO - 250M
        _mint(saleContractAddress, 250000000 * 10 ** decimals());
        // Marketing - 40M
        _mint(marketing, 40000000 * 10 ** decimals());
        // Founders - 53M 200K
        _mint(founderPool, 53200000 * 10 ** decimals());
        // EcoSystem - 62M
        _mint(ecoSystem, 62000000 * 10 ** decimals());
        // SearchEngine - 42M 200k
        _mint(searchEngine, 42200000 * 10 ** decimals());
        // Advisors - 22M 300k
        _mint(advisor, 22300000 * 10 ** decimals());
        // Airdrop - 300K
        _mint(address(this), 300000 * 10 ** decimals());
        // VC - 100M
        _mint(_VCPool, 100000000 * 10 ** decimals());
        // BitForex - 150k
        _mint(address(this), BITFOREX_WORTH * 10 * 10 ** decimals());
        // Multi-Chain, NFT-Game Pool
        _mint(_msgSender(), 429850000 * 10 ** decimals());
    }

    function setAirDrop(address _user, uint256 _amount) external onlyOwner {
        airdropList[_user] = _amount;
    }

    function setAirDropBatch(
        address[] memory _users,
        uint256[] memory _amounts
    ) external onlyOwner {
        for (uint256 i = 0; i < _users.length; i++) {
            airdropList[_users[i]] = _amounts[i];
        }
    }

    function enableAirDrop() external onlyOwner {
        airDropEnable = 1;
    }

    function disableAirDrop() external onlyOwner {
        airDropEnable = 0;
    }

    function toBitForex(address _bitForex) external onlyOwner {
        bitForex = _bitForex;
        _transfer(address(this), _bitForex, BITFOREX_WORTH * 10 * 10 ** decimals());
    }

    function withdrawToken() external onlyOwner {
        uint256 balance = balanceOf(address(this));
        require(balance > 0, "No tokens to withdraw");
        _transfer(address(this), owner(), balance);
    }
}