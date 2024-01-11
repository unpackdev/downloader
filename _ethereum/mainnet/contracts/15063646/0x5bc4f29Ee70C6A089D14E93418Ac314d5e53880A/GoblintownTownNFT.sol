// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW    WMMMMMMMMMMMMMMMMMMMMMMMWWWWWWW          WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW  WWW  WMMMMMMMMMMMMMMMMMMMW                  WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMWWWWWWWWMMMMMMMMMMMMMMMMMW MMMW  WMMMMW MMMMMMMMMMMMMWWWWWWMMW  WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW  MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMW            WMMMMMMMMMMMMMMW WMMW  WMMMM  WMMW  WMMMMMMMMMMMMMMW  WMMMMMW     WWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW  WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWMMMMMMMMMMMM
// MMW   WMMMMMMMMW  WMMMMMMMMMMMMMW WW   WMMMMM  WMMW K WMMMMMMMMMMMMMW  WMMMW           WWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW   WWWWWWMMMMMMMMMMMMMMMMMMMMMMW  MMMMMMMMW M
// MWW WMMMMMMMMMMW  WMMMMMMWWWMMMMW      WWWMMM  WMMW   WMMMMMMMMMMMMMW  WMMW  WMMMWWW     WMMMMMMMMMMMMW  WMWWWWMMMMMMMMMMWWWW          WWMMMMMMMMMMMMMMMMMMMMMW  WMMMMMMM  M
// MMW WMMMMMMMMMMW  MMMW         WW WMMMMMW  MM  WMMMMMMWWWW    WMMMMMW  WMMW  WMMMMMMW    WMMMMMMMMMMWWW         MMMMMMMMWWWWWW    WWMMMMMMMMMMMMMMMMMMMMMMMMMMW   WMMMMMW  M
// MMW  WMMMMMMMWW   WMW  WMMMMMW     MMMMMMW WM  WMMMMWW     WW  WMMMMW  WMM   WMMMMMM    WMWWWMMMWWMMW W    WWW   MMMMMMMMMMMMMW   MMMMMMW     WMMMMWMMMMMMMW WW    WMMMM K M
// MMMW   WWWWWW  W  WM  WMMMMMMMM    WMMMMMW WMW WMMMW W   WMMMW  WMMMW  WMMW   WMMMMW    MMW WMMW  MMW W    MMMM  WMMMMMMMMMMMMW   WMMMW    WWW  WMWWWMWWWMMW WM WM  WMMW  WM
// MMMMMWW     WWWM  WW  WMMMMMMMW WW WMMMMM  WMW WMMW  MW  MMMMM  WMMMW  WMMMW         WMMMMW WMMW  MM  W   WMMMMW WMMMMMMMMMMMMM   WMMM   WMMMMW  WW WM  WMM  WM  MW  WMW  WM
// MWMMMMMMMMMMMMMM  WMW  WMMMW  WWMW WMMMW   MMW WMMW  MW  WMMMM   MMMW  WMMMMWWW  WWWMMMMMMW  MW   WW  W   WMMMMW  MMMMMMMMMMMMMW  WMMW   MMMMMW  WW WM  WMM  WM  MMW  W   MM
// M  MMMMMMMMMMMMW  WMMWWW   WWWMMMM  WWW  WMMMW WMMW  MW  WMMMMW WMMMW  WMMMMMMMMMMMMMMMMMMW         K W   WMMMMW  WMMMWWWWMMMMMW  WMMW   WMMWW   WM  W   WW  WM  MMMW    WMM
// MW  MMMMMMMMMMW   WMMMMMMMMMMMMMMW    WMMMMMMW WMMW WMW   MMMMWWMMMMW  WMMMMMMMMMMMMMMMMMMMMWWWWMMW  WW   WMMMMMWWMMMW K  MMMMMW  WMMMW         WMMW        WMM  WMMM    WMM
// MMW  WMMMMMMMM  WWMMMMMMMMMMMMMMMMMMMMMMMMMMMW WMMMWMMMWWWMMMMMMMMMMM  MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWMMMMMMMMMMMMW   WMMMMMW   WMMMMW     WWMMMMMWWMMWWWMMM  WMMMMWWWMMM
// MMMW  WWWWWW  WWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW    WMMMMMMMMMMMMMMMMMMMMMMMMMMWWMMMMMMMMMM
// MMMMM      WWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Signer.sol";

contract GoblintownTownNFT is ERC721A, Ownable, ReentrancyGuard, Signer {
    string public townLocation;
    bool public explorable = false;
    uint256 public explorableTown = 9999;
    uint256 public meeneth = 5000000000000000;
    mapping(address => uint256) public goblins;
    mapping(address => uint256) public earlyGoblins;

    constructor() ERC721A("GoblintownTown", "gOblIntOwnTOWN") {}

    function _baseURI() internal view virtual override returns (string memory) {
        return townLocation;
    }

    function meenEarly(bytes memory signature) external payable nonReentrant {
        uint256 allTown = totalSupply();
        require(allTown + 1 <= explorableTown, "sOwEE All mEEned");
        require(msg.sender == tx.origin, "nOt gOblIn");
        require(msg.value >= meeneth, "mOrEth");
        require(earlyGoblins[msg.sender] < 1, "dOn bE grEEdy");

        bytes32 _message = prefixed(
            keccak256(abi.encodePacked(msg.sender, address(this)))
        );
        require(
            recoverSigner(_message, signature) == signerAddress,
            "nEEd sIgn!"
        );

        reeFundXtraa(msg.value);
        _safeMint(msg.sender, 1);
        earlyGoblins[msg.sender] += 1;
    }

    function meen() external payable nonReentrant {
        uint256 allTown = totalSupply();
        require(explorable, "bE pAtIEnt");
        require(allTown + 1 <= explorableTown, "sOwEE All mEEned");
        require(msg.sender == tx.origin, "nOt gOblIn");
        require(msg.value >= meeneth, "mOrEth");
        require(goblins[msg.sender] < 1, "dOn bE grEEdy");
        reeFundXtraa(msg.value);
        _safeMint(msg.sender, 1);
        goblins[msg.sender] += 1;
    }

    function meenMany(address townOwner, uint256 _exploringTown)
        public
        onlyOwner
    {
        uint256 allTown = totalSupply();
        require(allTown + _exploringTown <= explorableTown);
        _safeMint(townOwner, _exploringTown);
    }

    function makeExplorable(bool _explore) external onlyOwner {
        explorable = _explore;
    }

    function giveTownLocation(string memory _location) external onlyOwner {
        townLocation = _location;
    }

    function reeFundXtraa(uint256 _senderValue) private {
        uint256 _exceededValue = _senderValue - meeneth;

        if (_exceededValue > 0) {
            (bool success, ) = payable(msg.sender).call{value: _exceededValue}(
                ""
            );
            require(success, "Transfer failed");
        }
    }

    function reedimFund() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "Transfer failed");
    }
}
