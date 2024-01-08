// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./OwnableUpgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";

interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

// The MAP can grow in the future :D
contract MarzLand is ERC721EnumerableUpgradeable, OwnableUpgradeable {
    // total plots
    uint256 public constant MAX_PLOTS = 20_000;

    // plot grid width
    uint256 public constant GRID_WIDTH = 200;

    // plot grid height
    uint256 public constant GRID_HEIGHT = 100;

    // FYI: making it a little harder for bots
    //      also next month's rent /\
    uint256 public constant CLAIM_FEE = 0.025 * (10**18);

    // early settlers have it easy
    // delay after which fee kicks in (first 10% is free)
    uint256 public constant FEE_DELAY = 2000;

    // plots reserved for public (rest for loot holders)
    uint256 public constant PUBLIC_PLOTS_RESERVED = 12234;

    // address of the loot contract
    address public lootNFT;

    // loot dao
    address public lootDAO;

    // loot plots
    mapping(uint256 => bool) public lootPlotsCalimed;

    // remaining public plots
    uint256 public publicPlotsAvailable;

    //--------------------------------------------------------------------------
    // Public functions
    function initialize(
        address lootNFT_,
        address lootDAO_,
        uint256[] memory seeds,
        uint256[] memory daoLandingSites) external initializer {
        __ERC721_init("Marz Land", "MARZ-LAND");
        __ERC721Enumerable_init();
        __Ownable_init();

        // set references
        lootNFT = lootNFT_;
        lootDAO = lootDAO_;
        publicPlotsAvailable = PUBLIC_PLOTS_RESERVED;

        // seed civilization with city centers
        for (uint256 i = 0; i < seeds.length; i++) {
            uint256 plotID = seeds[i];
            // yolo require(plotID < MAX_PLOTS);
            _mint(address(this), plotID);
        }

        // dao landing site pre-mine
        for (uint256 i = 0; i < daoLandingSites.length; i++) {
            uint256 plotID = daoLandingSites[i];
            // yolo require(plotID < MAX_PLOTS);
            _mint(lootDAO, plotID);
        }

        // Initial distribution:
        // 8000 + 12234 + 225 + 9 = 20000
        // Loot holders + public pool + dao + seeds
    }

    // claim public plot
    function claimTo(address to, uint256 plotID) external payable {
        require(publicPlotsAvailable != 0, "MarzLand: No more public plots");

        _mintPlot(to, plotID);

        publicPlotsAvailable--;
    }

    // claim plot with loot
    function claimWithLoot(uint256 lootID, uint256 plotID) external payable {
        require(!lootPlotsCalimed[lootID], "MarzLand: Plot already claimed by loot owner");

        _mintPlot(IERC721(lootNFT).ownerOf(lootID), plotID);

        lootPlotsCalimed[lootID] = true;
    }

    // claim fees
    function claimFees() external onlyOwner {
        payable(_msgSender()).transfer(address(this).balance);
    }

    //--------------------------------------------------------------------------
    // Public view/pure functions
    function hasAdjacentPlot(uint256 plotID) public view returns (bool) {
        uint256 MIN_X = 0;
        uint256 MIN_Y = 0;
        uint256 MAX_X = GRID_WIDTH - 1;
        uint256 MAX_Y = GRID_HEIGHT - 1;

        uint256 x0;
        uint256 x1;
        uint256 x2;
        uint256 y0;
        uint256 y1;
        uint256 y2;
        // current cell is (x1,y1)
        // neighbors are:
        // (x0,y0), (x0,y1), (x0,y2)
        // (x1,y0), _______, (x1,y2)
        // (x2,y0), (x2,y1), (x2,y2)
        (x1, y1) = getXY(plotID);
        x0 = (x1 == MIN_X) ? MAX_X : x1 - 1;
        x2 = (x1 == MAX_X) ? MIN_X : x1 + 1;
        y0 = (y1 == MIN_Y) ? MAX_Y : y1 - 1;
        y2 = (y1 == MAX_Y) ? MIN_Y : y1 + 1;

        return (
            exists(getPlotID(x0, y0)) ||
            exists(getPlotID(x0, y1)) ||
            exists(getPlotID(x0, y2)) ||
            exists(getPlotID(x1, y0)) ||
            exists(getPlotID(x1, y2)) ||
            exists(getPlotID(x2, y0)) ||
            exists(getPlotID(x2, y1)) ||
            exists(getPlotID(x2, y2))
        );
    }

    function exists(uint256 plotID) public view returns (bool) {
        return _owners[plotID] != address(0);
    }

    // x,y to plotID
    function getPlotID(uint256 x, uint256 y) public pure returns (uint256) {
        return x + GRID_WIDTH * y;
    }

    // plotID to x,y
    function getXY(uint256 plotID) public pure returns (uint256, uint256) {
        return (plotID % GRID_WIDTH, plotID / GRID_WIDTH);
    }


    //--------------------------------------------------------------------------
    // Private functions
    function _mintPlot(address to, uint256 plotID) private {
        // valid plotID
        require(plotID < MAX_PLOTS, "MarzLand: Plot out of bounds");

        // is already claimed
        require(_owners[plotID] == address(0), "MarzLand: Plot already claimed");

        // can claim?
        require(hasAdjacentPlot(plotID), "MarzLand: Plot not accessible to claim");

        // check fee
        if(totalSupply() > FEE_DELAY) {
            require(msg.value >= CLAIM_FEE, "MarzLand: Claim fee required");
        }

        // yay!
        _mint(to, plotID);
    }
}
