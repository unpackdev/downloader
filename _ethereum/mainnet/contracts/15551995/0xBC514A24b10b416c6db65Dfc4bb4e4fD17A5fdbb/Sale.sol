// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";
import "./Counters.sol";
import "./Pausable.sol";
import "./ElementaVerse.sol";

contract Sale is ReentrancyGuard, Ownable, Pausable {

    using Counters for Counters.Counter;

    ElementaVerse public elementaVerse;
    Information public InformationSale;
    Counters.Counter public mintCount;

    struct Information {
        uint32 mintMax;
        uint32 limitPresalePerAddress;
        uint32 limitTotalPerAddress;
        uint128 timeStart;
        uint128 timeEnd;
        uint128 publicSaleTimeEnd;
        uint256 pricePresale;
        uint256 pricePublicsale;
        bytes32 root;
    }

    mapping (address => uint256)  public historyMint;

    address public beneficiary;

    event Mint(address account, string round, uint256 price, uint256 amount);

    
    modifier isMax(uint amount) {
        require(
            amount+mintCount.current() <= InformationSale.mintMax,
            "Sale: Already sold out"
        );
        _;
    }


    modifier publicSaleEnd() {
        require(block.timestamp < InformationSale.publicSaleTimeEnd, "Sale: Public sale is over.");
        _;
    }
    modifier isInformationSet() {
        require(
            InformationSale.limitPresalePerAddress != 0,
            "Mint: Information sale has not been set"
        );
        _;
    }

    modifier isPresaleStart() {
        require(
            block.timestamp > InformationSale.timeStart,
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
        ElementaVerse _elementaVerse
    ) {
        elementaVerse = _elementaVerse;
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function pause() public onlyOwner {
        _pause();
    }
    function _buy(uint _amount, uint _price) internal whenNotPaused isInformationSet isPresaleStart isPayEnough(_price, _amount) isMax(_amount) nonReentrant publicSaleEnd{
        for (uint256 i = 0; i < _amount; i++) {
            elementaVerse.mintTo(_msgSender());
        }
        historyMint[_msgSender()] += _amount;
        mintCount.increment();
    }

    function presaleBuy(uint256 _amount, bytes32[] calldata _proof)
        external
        payable
        isValidMerkleProof(_proof)
    {
        require(
            block.timestamp < InformationSale.timeEnd,
            "Mint: Presale is over"
        );
        require(
            historyMint[_msgSender()] + _amount <=
                InformationSale.limitPresalePerAddress,
            "Mint: Limit presale per address exceeded"
        );
        _buy(_amount, InformationSale.pricePresale);
        emit Mint(_msgSender(), "Private", msg.value, _amount);
    }

    function publicSale(uint256 _amount)
        external
        payable
    {
        require(
            block.timestamp > InformationSale.timeEnd,
            "Mint: Presale is not over"
        );
        require(
            historyMint[_msgSender()] + _amount <=
                InformationSale.limitTotalPerAddress,
            "Mint: Limit per address exceeded"
        );
        _buy(_amount, InformationSale.pricePublicsale);

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
            elementaVerse.mintTo(receiver);
        }
    }

    function withdraw() external onlyOwner nonReentrant {
        require(
            beneficiary != address(0),
            "Withdraw: Gnosis Wallet has not been set"
        );

        if (address(this).balance > 0) {
            payable(beneficiary).transfer(address(this).balance);
        }
    }

    function setBeneficiary(address _beneficiary) external onlyOwner {
        beneficiary = _beneficiary;
    }

    function setInformation(Information calldata _information)
        external
        onlyOwner
    {
        InformationSale = _information;
    }

    function getInformation() external view returns(uint32, uint32, uint32, uint128,uint128, uint128, uint, uint, bytes32, uint){
        return (InformationSale.mintMax,
         InformationSale.limitPresalePerAddress,
         InformationSale.limitTotalPerAddress,
         InformationSale.timeStart,
         InformationSale.timeEnd,
         InformationSale.publicSaleTimeEnd,
         InformationSale.pricePresale,
         InformationSale.pricePublicsale,
         InformationSale.root,
         mintCount.current());
    }
}
