// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";
import "./Pausable.sol";
import "./ImpactFantasy.sol";

contract Sale is ReentrancyGuard, Ownable, Pausable {
    ImpactFantasy public impactFantasy;
    Information public InformationSale;

    struct Information {
        uint maxMint;
        uint32 limitPresalePerAddress;
        uint32 limitTotalPerAddress;
        uint128 presaleStart;
        uint128 presaleEnd;
        uint128 publicSaleEnd;
        uint256 pricePresale;
        uint256 pricePublicsale;
        bytes32 root;
    }

    mapping (address => uint256) public historyMint;

    address public beneficiary;

    event Mint(address account, string round, uint256 price, uint256 amount);

    modifier isInformationSet() {
        require(
            InformationSale.limitPresalePerAddress != 0,
            "Mint: Information sale has not been set"
        );
        _;
    }

    modifier isPresaleStart() {
        require(
            block.timestamp > InformationSale.presaleStart,
            "Mint: Presale has not started"
        );
        _;
    }

    modifier isValidMerkleProof(bytes32[] calldata _proof) {
        require(
            MerkleProof.verify(
                _proof,
                InformationSale.root,
                keccak256(abi.encodePacked(_msgSender()))
            ) == true,
            "Mint: You are not in Whitelist"
        );
        _;
    }

    modifier isPayEnough(uint256 price, uint256 _amount) {
        require(price * _amount <= msg.value, "Mint: Not enough ethers sent");
        _;
    }

    constructor(
        ImpactFantasy _impactFantasy
    ) {
        impactFantasy = _impactFantasy;
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function pause() public onlyOwner {
        _pause();
    }
    modifier isMaxMint(uint amount){
        require(impactFantasy.currentSupply()+amount <= InformationSale.maxMint, "Sale: sold out");
        _;
    }
    function presaleBuy(uint256 _amount, bytes32[] calldata _proof)
        external
        payable
        whenNotPaused
        isInformationSet
        isPresaleStart
        isValidMerkleProof(_proof)
        isPayEnough(InformationSale.pricePresale, _amount)
        nonReentrant
        isMaxMint(_amount)
    {
        require(
            block.timestamp < InformationSale.presaleEnd,
            "Mint: Presale is over"
        );

        require(
            historyMint[_msgSender()] + _amount <=
                InformationSale.limitPresalePerAddress,
            "Mint: Limit presale per address exceeded"
        );

        for (uint256 i = 0; i < _amount; i++) {
            impactFantasy.mintTo(_msgSender());
        }

        historyMint[_msgSender()] += _amount;

        emit Mint(_msgSender(), "Private", msg.value, _amount);
    }

    function publicSale(uint256 _amount)
        external
        payable
        whenNotPaused
        isInformationSet
        isPresaleStart
        isPayEnough(InformationSale.pricePublicsale, _amount)
        nonReentrant
        isMaxMint(_amount)
    {
        require(
            block.timestamp > InformationSale.presaleEnd,
            "Mint: Presale is not over"
        );

        require(
            block.timestamp < InformationSale.publicSaleEnd,
            "Mint: Public Sale is over"
        );

        require(
            historyMint[_msgSender()] + _amount <=
                InformationSale.limitTotalPerAddress,
            "Mint: Limit per address exceeded"
        );

        for (uint256 i = 0; i < _amount; i++) {
            impactFantasy.mintTo(_msgSender());
        }

        historyMint[_msgSender()] += _amount;

        emit Mint(_msgSender(), "Public", msg.value, _amount);
    }

    function airDrop(address receiver, uint256 _amount)
        external
        whenNotPaused
        isInformationSet
        onlyOwner
    {
        require(receiver != address(0), "Airdrop: receiver empty");

        for (uint256 i = 0; i < _amount; i++) {
            impactFantasy.mintTo(receiver);
        }
    }

    function withdraw() external onlyOwner nonReentrant {
        require(
            beneficiary != address(0),
            "Sale: beneficiary Wallet has not been set"
        );

        require(address(this).balance > 0, "Sale: balance empty");
        payable(beneficiary).transfer(address(this).balance);
    }

    function setbeneficiary(address _beneficiary) external onlyOwner {
        beneficiary = _beneficiary;
    }

    function setInformation(Information calldata _information)
        external
        onlyOwner
    {
        InformationSale = _information;
    }
}
