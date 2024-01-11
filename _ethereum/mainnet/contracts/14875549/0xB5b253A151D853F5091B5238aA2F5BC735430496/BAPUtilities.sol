// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.12;
import "./ERC1155.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";

contract BAPUtilities is ERC1155, ReentrancyGuard, Ownable {
    // Contract name
    string public name;
    // Contract symbol
    string public symbol;
    bool public open = false;
    address public orchestrator;
    uint256 public initialMintingTimestamp = 0;
    uint256 public constant INCUBATOR = 1;
    uint256 public constant MERGER_ORB = 2;
    uint256 public constant INCUBATOR_AMOUNT = 12500;
    uint256 public constant MERGER_ORB_AMOUNT = 1490;
    uint256 public incubatorsPurchased = 0;
    uint256 public mergerOrbsPurchased = 0;
    constructor(
        string memory _url,
        string memory _name,
        string memory _symbol,
        address _orchestrator
    ) ERC1155(_url) {
        name = _name;
        symbol = _symbol;
        orchestrator = _orchestrator;
    }

    function purchaseIncubator() external nonReentrant {
        require(open, "Contract is closed");
        require(msg.sender == orchestrator, "Invalid sender");
        require(incubatorsPurchased < INCUBATOR_AMOUNT, "Invalid sender");
        incubatorsPurchased++;
        _mint(tx.origin, INCUBATOR, 1, "");
    }

    function purchaseMergerOrb() external nonReentrant {
        require(open, "Contract is closed");
        require(msg.sender == orchestrator, "Invalid sender");
        require(mergerOrbsPurchased < MERGER_ORB_AMOUNT, "Invalid sender");
        mergerOrbsPurchased++;
        _mint(tx.origin, MERGER_ORB, 1, "");
    }

    function setOpen(bool _open) external onlyOwner {
        //Once the contract is open the minting window starts
        if (initialMintingTimestamp == 0 && _open == true) {
            initialMintingTimestamp = block.timestamp;
        }
        open = _open;
    }

    function setURI(string memory newuri) external onlyOwner {
        _setURI(newuri);
    }

    function totalSupply() public view returns(uint256){
        return incubatorsPurchased + mergerOrbsPurchased;
    }

    function burn(uint256 id, uint256 amount) external {
       require(msg.sender == orchestrator, "Invalid sender");
      _burn(tx.origin, id, amount);
    }
}
