// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;
import "./ERC721.sol";
import "./Owned.sol";
import "./LibString.sol";
import "./SafeTransferLib.sol";

//////////////////////////////////////////////////////
//                                                  //
//                                                  //
//    ██████████████████████████████████████████    //
//    █                                        █    //
//    █                                        █    //
//    █                                        █    //
//    █                                        █    //
//    █    __________  ___________          __ █    //
//    █   / ____/ __ \/_  __/ __(_)__  ____/ / █    //
//    █  / /   / /_/ / / / / /_/ / _ \/ __  /  █    //
//    █ / /___/ _, _/ / / / __/ /  __/ /_/ /   █    //
//    █ \____/_/ |_| /_/ /_/ /_/\___/\__,_/    █    //
//    █                                        █    //
//    █                                        █    //
//    █                                        █    //
//    █                                        █    //
//    ██████████████████████████████████████████    //
//    ████████████████░░░░░░░░░█████████████████    //
//    ██████████████████████████████████████████    //
//    ███■█■███■█■█████████████ ■ █ ■ ████■■■■██    //
//    ██████████████████████████████████████████    //
//                                                  //
//                                                  //
//////////////////////////////////////////////////////

interface CRTfiedOpenEdition {
    function balanceOf(address _owner) external view returns (uint256);
}

contract CRTfied is ERC721, Owned {
    /* -------------------------------------------------------------------------- */
    /*                                  CONSTANTS                                 */
    /* -------------------------------------------------------------------------- */
    CRTfiedOpenEdition private crtOpenEdition =
        CRTfiedOpenEdition(0x301254AA648cF7C0B51aDDcd5d208ef5De0e4D5d);

    uint256 public constant MAX_SUPPLY = 480;
    uint256 public constant MAX_PER_MINT = 4;
    uint256 public price = 0.07 ether;
    bool public mintEnabled = true;
    bool public publicMintEnabled = false;

    /* -------------------------------------------------------------------------- */
    /*                                    DATA                                    */
    /* -------------------------------------------------------------------------- */
    string private _baseURI;
    address private _dev;
    address private _owner1;
    address private _owner2;
    uint256 public totalSupply = 0;
    mapping(address => bool) public allowList;

    /* -------------------------------------------------------------------------- */
    /*                               EVENTS & ERRORS                              */
    /* -------------------------------------------------------------------------- */
    error NotAllowed();
    error NotCurrentDev();
    error NotCurrentOwner();
    error InvalidMintAmount();
    error TooManyPerMint();
    error NotEnoughTokens();
    error InvalidMintFee();

    /* -------------------------------------------------------------------------- */
    /*                                    INIT                                    */
    /* -------------------------------------------------------------------------- */
    constructor(string memory baseURI, address dev, address  owner1, address owner2) ERC721("CRTfied", "CRTFIED") Owned(msg.sender) {
        _baseURI = baseURI;
        _dev = dev;
        _owner1 = owner1;
        _owner2 = owner2;
    }

    /* -------------------------------------------------------------------------- */
    /*                                   MINTING                                  */
    /* -------------------------------------------------------------------------- */
    function mint(uint256 amount) external payable {
        if (amount <= 0) revert InvalidMintAmount();
        if (amount > MAX_PER_MINT) revert TooManyPerMint();
        if (msg.value != amount * price) revert InvalidMintFee();
        // if not in public mint, run some checks
        if (!publicMintEnabled) {
            // revert if sender has no OE and is not on allowlist
            if (crtOpenEdition.balanceOf(msg.sender) == 0 && !allowList[msg.sender]) {
                revert NotAllowed();
            }
        }

        if (totalSupply + amount > MAX_SUPPLY) revert NotEnoughTokens();

        for (uint256 i = 0; i < amount; i++) {
            uint256 tokenId = totalSupply + 1;
            _mint(msg.sender, tokenId);
            totalSupply++;
        }
    }

    /* -------------------------------------------------------------------------- */
    /*                                  METADATA                                  */
    /* -------------------------------------------------------------------------- */
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        return string.concat(_baseURI, LibString.toString(tokenId));
    }

    /* -------------------------------------------------------------------------- */
    /*                                    ADMIN                                   */
    /* -------------------------------------------------------------------------- */
    function withdraw() external {
        if (msg.sender != _dev && msg.sender != _owner1 && msg.sender != _owner2) {
            revert NotAllowed();
        }
        uint devCut = address(this).balance * 75/1000;
        uint ownerCut = (address(this).balance - devCut) / 2;
        SafeTransferLib.safeTransferETH(_dev, devCut);
        SafeTransferLib.safeTransferETH(_owner1, ownerCut);
        SafeTransferLib.safeTransferETH(_owner2, ownerCut);
    }

    function setDevAddress(address newDev) external {
        if (msg.sender != _dev) revert NotCurrentDev();
        _dev = newDev;
    }

    function setOwner1Address(address newOwner) external {
        if (msg.sender != _owner1) revert NotCurrentOwner();
        _owner1 = newOwner;
    }

    function setOwner2Address(address newOwner) external {
        if (msg.sender != _owner2) revert NotCurrentOwner();
        _owner2 = newOwner;
    }

    function setBaseURI(string calldata newURI) external onlyOwner {
        _baseURI = newURI;
    }

    function setMintPrice(uint256 newPrice) external onlyOwner {
        price = newPrice;
    }

    function setPublicMintEnabled(bool newState) external onlyOwner {
        publicMintEnabled = newState;
    }

    function setMintEnabled(bool newState) external onlyOwner {
        mintEnabled = newState;
    }

    function setOpenEditionAddress(address newAddress) external onlyOwner {
        crtOpenEdition = CRTfiedOpenEdition(newAddress);
    }

    function addAllowList(address[] calldata addresses) external onlyOwner {
        for (uint i = 0; i < addresses.length; i++) {
            allowList[addresses[i]] = true;
        }
    }
}