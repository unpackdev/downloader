// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721AVantabox.sol";

contract Vantabox is ERC721AVantabox, Ownable, ReentrancyGuard {

    string public baseTokenURI;
    uint256 public constant MINT_PRICE = 0.05 ether;

    mapping(address => uint256) public referralCount;
    mapping(address => uint256) public claimedCount;
    mapping(address => address[]) public walletReferral;
    address public ownerAddress;

    constructor(string memory baseURI, address _owner) ERC721AVantabox("Vantabox", "VANTABOX") {
        baseTokenURI = baseURI;
        ownerAddress = _owner;
        _safeMint(_owner, 1, ownerAddress);
    }

    function _baseURI() internal view virtual override returns(string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function mintVantabox(address _referrer) external payable {
        require(msg.value >= MINT_PRICE, "Invalid value");
        require(balanceOf(_referrer) > 0, "Invalid Referral");
        _safeMint(msg.sender, 1, _referrer);

        referralCount[_referrer] += 1;
        walletReferral[_referrer].push(msg.sender);
    }

    function claimBalance(address _wallet) public view returns(uint256 balance) {
        uint256 claimQty = referralCount[_wallet] - claimedCount[_wallet];
        balance = claimQty * MINT_PRICE * 3/4;
    }

    function claim() external nonReentrant {
        require(claimedCount[msg.sender] < referralCount[msg.sender], "All claimed");
        uint256 claimQty = referralCount[msg.sender] - claimedCount[msg.sender];
        uint256 claimReward =  claimQty * MINT_PRICE * 3/4;
        uint256 claimFee =  claimQty * MINT_PRICE * 1/4;
        claimedCount[msg.sender] += claimQty;
        payable(msg.sender).transfer(claimReward);
        payable(ownerAddress).transfer(claimFee);
    }

}
