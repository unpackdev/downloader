// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./ERC20.sol";
import "./Address.sol";
import "./Strings.sol";

contract IQCoin is ERC20, Ownable {
    uint256 public constant MAX_SUPPLY = 1_000_000_000 ether;
    uint256 public constant POOL_SUPPLY = 250_000_000 ether;
    uint256 public constant PLAYER_SUPPLY = 500_000_000 ether;

    address public constant ECOSYSTEM_ADDRESS1 =
        0xeBD0859172451336780fBCf5B49Aa20F92C3F330;
    address public constant ECOSYSTEM_ADDRESS2 =
        0x466419aa5b5DBb1FF4A0Cb0e2433EFCA24cB2974;

    uint256 private playerClaimed;
    mapping(address => bool) private claimers;
    mapping(address => bool) private burners;

    constructor() ERC20("IQCoin", "IQ") {
        require(MAX_SUPPLY == PLAYER_SUPPLY + POOL_SUPPLY * 2, "SUPPLY WRONG");
        _mint(ECOSYSTEM_ADDRESS1, POOL_SUPPLY);
        _mint(ECOSYSTEM_ADDRESS2, POOL_SUPPLY);
    }

    function playerClaim(address holder, uint256 amount) external {
        require(claimers[msg.sender], "Invalid Calaimer");
        require(playerClaimed + amount <= PLAYER_SUPPLY, "Exceed supply");
        playerClaimed += amount;
        _mint(holder, amount);
    }

    function mintRest(address to) external onlyOwner {
        uint256 rest = PLAYER_SUPPLY - playerClaimed;
        if (rest > 0) {
            _mint(to, rest);
        }
    }

    function addClaimer(address claimer) external onlyOwner {
        claimers[claimer] = true;
    }

    function removeClaimer(address claimer) external onlyOwner {
        delete claimers[claimer];
    }

    function addBurner(address burner) external onlyOwner {
        burners[burner] = true;
    }

    function removeBurner(address burner) external onlyOwner {
        delete burners[burner];
    }

    function burn(address from, uint256 amount) external {
        require(burners[msg.sender], "No auth");
        _burn(from, amount);
    }

    function playerRest() public view returns (uint256) {
        return PLAYER_SUPPLY - playerClaimed;
    }
}
