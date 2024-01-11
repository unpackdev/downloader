//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./console.sol";

/*
 * https://docs.openzeppelin.com/contracts/4.x/erc20
 */
import "./ERC20.sol";

/*
 * https://docs.openzeppelin.com/contracts/4.x/access-control#ownership-and-ownable
 */
import "./Ownable.sol";

contract AnticorruptionCoin is Ownable, ERC20 {
    constructor() ERC20("AnticorruptionCoin", "ACC") {
        uint256 initialSupply = 100000000000;
        _mint(msg.sender, initialSupply);
        lastMintingTimestamp = block.timestamp;
        if (block.chainid == 1) {
            // MainNet
            newTokensTime = 30 days;
        } else {
            // test nets
            newTokensTime = 10 minutes;
        }
        console.log("Deploying contracts with initial supply of", initialSupply, "tokens");
    }

    // see: https://docs.openzeppelin.com/contracts/4.x/erc20#a-note-on-decimals
    function decimals() public view virtual override returns (uint8) {
        return 3;
    }

    /*
     * time period between minting new tokens
     */
    uint256 public newTokensTime;

    uint256 public lastMintingTimestamp;

    uint256 public newTokensBatchSize = 500000000;

    address public admin;

    modifier onlyOwnerOrAdmin() {
        require(owner() == _msgSender() || admin == _msgSender(), "Caller is not the owner or admin");
        _;
    }

    function mint() public onlyOwnerOrAdmin {
        require(block.timestamp - lastMintingTimestamp > newTokensTime, "Need to wait");
        _mint(msg.sender, newTokensBatchSize);
        lastMintingTimestamp = block.timestamp;
        console.log("New tokens minted");
    }

    function burn(uint256 amount) public onlyOwner {
        _burn(msg.sender, amount);
    }

    function setAdmin(address _admin) public onlyOwner {
        admin = _admin;
    }
}
