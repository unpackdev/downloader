//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.11;
import "./PaymentSplitter.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";
import "./IVoyager.sol";

contract PublicVoyager is PaymentSplitter, Ownable, ReentrancyGuard, Pausable {
    IVoyager public voyagerNFT;
    mapping(address => bool) private admins;
    mapping(address => uint256) public count;
    uint256 public max = 2;

    address[] shareholders = [
        0x02ebD600284A3779e587151D6185421b39c7B68c,
        0x89ea4b96F76780ACf0fB0b4347E8B2dD8656FfF0
    ];
    uint256[] equities = [95,5];

    constructor() PaymentSplitter(shareholders, equities){
        pause();
    }

    function mint(uint256 quantity) external payable nonReentrant whenNotPaused {
        require(msg.value >= voyagerNFT.price() * quantity, "Insufficient amount");
        require(count[msg.sender] + quantity <= max, "Already minted");

        count[msg.sender] += quantity;
        voyagerNFT.adminMint(quantity, msg.sender);
    }

    function pause() public adminOrOwner {
        _pause();
    }

    function unpause() public adminOrOwner {
        _unpause();
    }

    function setVoyager(IVoyager _voyager) external adminOrOwner {
        voyagerNFT = _voyager;
    }

    function setMax(uint256 _max) external adminOrOwner {
        max = _max;
    }

    function addAdmin(address _admin) external adminOrOwner {
        admins[_admin] = true;
    }

    function removeAdmin(address _admin) external adminOrOwner {
        admins[_admin] = false;
    } 

    modifier adminOrOwner() {
        require(admins[_msgSender()] || _msgSender() == owner(), "Unauthorized");
        _;
    }
}