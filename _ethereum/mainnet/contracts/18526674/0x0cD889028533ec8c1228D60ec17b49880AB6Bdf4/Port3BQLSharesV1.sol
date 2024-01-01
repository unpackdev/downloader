// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "ERC721.sol";
import "IERC20.sol";
import "Ownable.sol";
import "ReentrancyGuard.sol";

contract Port3BQLSharesV1 is Ownable, ReentrancyGuard, ERC721{
    uint256 private _supply; // total supply
    uint256 private _tokenId; // current tokenId
    string private _baseUri;

    bool public allowRescueFund = true; 

    // get holders by _owners mapping
    // mapping(address owner => uint256) private _balances;
    // mapping(uint256 tokenId => address) private _owners;

    // === FT Model ====
    address public protocolFeeDestination;
    uint256 public protocolFeePercent = 50_000_000_000_000_000; // 5%
    address public sharesSubject;
    uint256 public subjectFeePercent = 50_000_000_000_000_000; // 5%

    event Trade(address trader, address subject, bool isBuy, uint256 shareAmount, uint256 ethAmount, uint256 protocolEthAmount, uint256 subjectEthAmount, uint256 supply);

    constructor(string memory _name, string memory _symbol, string memory _tokenUri, address _owner, address _sharesSubject) Ownable(_owner) ERC721(_name, _symbol) {

        _baseUri = _tokenUri;
        sharesSubject = _sharesSubject;
        protocolFeeDestination = _owner;
    }
    
    // === onlyOwner ====
    function setTokenURI(
        string memory _uri
    ) public onlyOwner{
        _baseUri = _uri;
    }

    function renounceRescueFund() public onlyOwner {
        allowRescueFund = false;
    }

    function setFeeDestination(address _feeDestination) public onlyOwner {
        protocolFeeDestination = _feeDestination;
    }

    function setProtocolFeePercent(uint256 _feePercent) public onlyOwner {
        protocolFeePercent = _feePercent;
    }

    function setSubjectFeePercent(uint256 _feePercent) public onlyOwner {
        subjectFeePercent = _feePercent;
    }

    function getPrice(uint256 supply, uint256 amount) public pure returns (uint256) {
        uint256 sum1 = supply == 0 ? 0 : (supply - 1) * (supply) * (2 * (supply - 1) + 1) / 6;
        uint256 sum2 = supply == 0 && amount == 1 ? 0 : (supply - 1 + amount) * (supply + amount) * (2 * (supply - 1 + amount) + 1) / 6;

        uint256 summation = sum2 - sum1;
        return summation * 1 ether / 810000;
    }

    function getBuyPrice(uint256 amount) public view returns (uint256) {
        return getPrice(_supply, amount);
    }

    function getSellPrice(uint256 amount) public view returns (uint256) {
        return getPrice(_supply - amount, amount);
    }

    function getBuyPriceAfterFee(uint256 amount) public view returns (uint256) {
        uint256 price = getBuyPrice(amount);
        uint256 protocolFee = price * protocolFeePercent / 1 ether;
        uint256 subjectFee = price * subjectFeePercent / 1 ether;
        return price + protocolFee + subjectFee;
    }

    function getSellPriceAfterFee(uint256 amount) public view returns (uint256) {
        uint256 price = getSellPrice(amount);
        uint256 protocolFee = price * protocolFeePercent / 1 ether;
        uint256 subjectFee = price * subjectFeePercent / 1 ether;
        return price - protocolFee - subjectFee;
    }
    
    // mint
    function mintShare() public payable nonReentrant {
        uint256 amount = 1;
        uint256 supply = _supply; 
        require(supply > 0 || super.owner() == msg.sender, "Only the owner can buy the first share");
        uint256 price = getPrice(supply, amount);
        uint256 protocolFee = price * protocolFeePercent / 1 ether;
        uint256 subjectFee = price * subjectFeePercent / 1 ether;
        require(msg.value >= price + protocolFee + subjectFee, "Insufficient payment");
        
        super._safeMint(msg.sender, _tokenId); // update balance automaticly
        _supply++;
        _tokenId++;

        emit Trade(msg.sender, sharesSubject, true, amount, price, protocolFee, subjectFee, supply + amount);
        (bool success1, ) = protocolFeeDestination.call{value: protocolFee}("");
        (bool success2, ) = sharesSubject.call{value: subjectFee}("");
        require(success1 && success2, "Unable to send funds");
    }
    
    // burn
    function burnShare(uint256 tokenId) public payable nonReentrant {
        uint256 amount = 1;
        uint256 supply = _supply;
        require(supply > amount, "Cannot sell the last share");
        uint256 price = getPrice(supply - amount, amount);
        uint256 protocolFee = price * protocolFeePercent / 1 ether;
        uint256 subjectFee = price * subjectFeePercent / 1 ether;

        require(super.ownerOf(tokenId) == msg.sender, "Not holder");
        require(super.balanceOf(msg.sender) >= amount, "Insufficient shares");

        super._burn(tokenId);
        _supply = supply - amount;

        emit Trade(msg.sender, sharesSubject, false, amount, price, protocolFee, subjectFee, supply - amount);
        (bool success1, ) = msg.sender.call{value: price - protocolFee - subjectFee}("");
        (bool success2, ) = protocolFeeDestination.call{value: protocolFee}("");
        (bool success3, ) = sharesSubject.call{value: subjectFee}("");
        require(success1 && success2 && success3, "Unable to send funds");
    }
    

    /**
     * @dev All tokens share the same URI
     */
    function tokenURI(uint256 tokenId) public override view returns (string memory) {
        return _baseUri;
    }


    /**
     * @dev Total supply of NFT
     */
    function totalSupply() public view returns (uint256) {
        return _supply;
    }

    /**
     * @dev latest tokenId of NFT
     */
    function currTokenId() public view returns (uint256) {
        return _tokenId;
    }


    /**
     * @dev Rescure fund of mistake deposit 
     */
    function rescueFund(address _recipient, address _tokenAddr, uint256 _tokenAmount) external onlyOwner{
        require(allowRescueFund == true, "Not allow for rescure fund");
        if (_tokenAmount > 0) {
            if (_tokenAddr == address(0)) {
                payable(_recipient).call{value: _tokenAmount}("");
            } else {
                IERC20(_tokenAddr).transfer(_recipient, _tokenAmount);
            }
        }

    }
    
}

