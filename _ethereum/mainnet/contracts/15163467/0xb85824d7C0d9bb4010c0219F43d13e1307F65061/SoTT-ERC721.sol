// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "./ERC721Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./SignedAllowance.sol";
import "./TimeweaverKeeperControl.sol";
import "./ReentrancyGuardUpgradeable.sol";

contract SoTT is Initializable, ERC721Upgradeable, OwnableUpgradeable, UUPSUpgradeable, SignedAllowance, TimeweaverKeeperControl, ReentrancyGuardUpgradeable {

// Author: @sec0ndstate
// Creator: Timekeeper Strongheart
//
//  .........._____..................._______..............._____................_____..........
//  ........./\....\................./::\....\............./\....\............../\....\.........
//  ......../::\....\.............../::::\....\.........../::\....\............/::\....\........
//  ......./::::\....\............./::::::\....\..........\:::\....\...........\:::\....\.......
//  ....../::::::\....\.........../::::::::\....\..........\:::\....\...........\:::\....\......
//  ...../:::/\:::\....\........./:::/~~\:::\....\..........\:::\....\...........\:::\....\.....
//  ..../:::/__\:::\....\......./:::/....\:::\....\..........\:::\....\...........\:::\....\....
//  ....\:::\...\:::\....\...../:::/..../.\:::\....\........./::::\....\........../::::\....\...
//  ..___\:::\...\:::\....\.../:::/____/...\:::\____\......./::::::\....\......../::::::\....\..
//  ./\...\:::\...\:::\....\.|:::|....|.....|:::|....|...../:::/\:::\....\....../:::/\:::\....\.
//  /::\...\:::\...\:::\____\|:::|____|.....|:::|....|..../:::/..\:::\____\..../:::/..\:::\____\
//  \:::\...\:::\...\::/..../.\:::\....\.../:::/..../..../:::/....\::/..../.../:::/....\::/..../
//  .\:::\...\:::\...\/____/...\:::\....\./:::/..../..../:::/..../.\/____/.../:::/..../.\/____/.
//  ..\:::\...\:::\....\........\:::\..../:::/..../..../:::/..../.........../:::/..../..........
//  ...\:::\...\:::\____\........\:::\__/:::/..../..../:::/..../.........../:::/..../...........
//  ....\:::\../:::/..../.........\::::::::/..../.....\::/..../............\::/..../............
//  .....\:::\/:::/..../...........\::::::/..../.......\/____/..............\/____/.............
//  ......\::::::/..../.............\::::/..../.................................................
//  .......\::::/..../...............\::/____/..................................................
//  ........\::/..../.................~~........................................................
//  .........\/____/............................................................................
//  ............................................................................................
// Version: 1.0.3

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    ////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////// Errors/Events //////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////

    error SaleIsClosed();
    error AlreadyHasOneToken();
    error TransferLockedUnauthorizedOrNotOwner();
    error NotEnoughFunds();
    error FailedTransfer();

    ////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////// Values ////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////

    struct QuantumStorage {
        bool TransferLocked;
        bool SaleOpen;
        string baseUri;
        uint64 timeCost;
    }

    QuantumStorage quantumStorage;

    uint256 internal tokenIndex;

    ////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////// Initializer ///////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////
    
    function initialize() initializer public {
        __ERC721_init("Society of Time Travelers", "SoTT");
        __Ownable_init();
        __UUPSUpgradeable_init();
        __TimeweaverKeeperControl_init();
        __ReentrancyGuard_init();
        quantumStorage.TransferLocked = true;
    }

    ////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////// Minting ///////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////


    function TimekeeperMint(address to) external onlyTimeweaver {
        if (balanceOf(to) > 0) {
            revert AlreadyHasOneToken();
        }
        _mint(to, tokenIndex);
        unchecked {
            ++tokenIndex;
        }
    }

    function TimeTravelerMint (bool whitelisted, uint256 nonce, bytes memory signature) external payable {
        if (!quantumStorage.SaleOpen) {
            revert SaleIsClosed();
        }
        if (balanceOf(msg.sender) > 0) { 
            revert AlreadyHasOneToken();
        }
        if (whitelisted) {
            validateSignature(msg.sender, nonce, signature);
            _mint(msg.sender, tokenIndex);
            unchecked {
                ++tokenIndex;
            }
        } else {
            if (msg.value < quantumStorage.timeCost) { 
                revert NotEnoughFunds();
            }
            _mint(msg.sender, tokenIndex);
            unchecked {
                ++tokenIndex;
            }
        }

    }

    function issueAccessPass(address[] calldata _addresses) external onlyTimeweaver {
        for (uint256 i = 0; i < _addresses.length; ++i) {
            if (balanceOf(_addresses[i]) > 0) {
                revert AlreadyHasOneToken();
            }
            _mint(_addresses[i], tokenIndex);
            unchecked {
                ++tokenIndex;
            }
        }
    }

    ////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////// Setters ///////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////

    function lockTransfer(bool locked) external onlyTimeweaver {
        quantumStorage.TransferLocked = locked;
    }

    function setSaleStatus(bool open) external onlyTimeweaver {
        quantumStorage.SaleOpen = open;
    }

    function setBaseUri(string memory uri) external onlyTimeweaver {
        quantumStorage.baseUri = uri;
    }

    function setAllowancesSigner(address newSigner) external onlyTimeweaver {
        _setAllowancesSigner(newSigner);
    }

    function setTimeCost(uint64 newTimeCost) external onlyTimeweaver {
        quantumStorage.timeCost = newTimeCost;
    }

    ////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////// Getters ///////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////

    function checkStorage() external view returns (bool TransferLocked, bool saleOpen, uint64 timeCost) {
        return (quantumStorage.TransferLocked, quantumStorage.SaleOpen, quantumStorage.timeCost);
    }

    function totalSupply() external view returns (uint256) {
        return tokenIndex;
    }
    
    ////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////// Overrides /////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////

    // from, to, tokenId 
    function _beforeTokenTransfer(address from, address, uint256) internal view override {
        if (quantumStorage.TransferLocked) { 
            if (!isOwnerOrZeroOrAuth(msg.sender,from)) {
            revert TransferLockedUnauthorizedOrNotOwner();
        }
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return quantumStorage.baseUri;
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyTimeweaver
        override
    {}

    ////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////// Special Functions /////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////


    function moveToken(address from, address to, uint256 tokenId) external onlyTimeweaver {
        if (to == address(0)) {
            _burn(tokenId);
        } else {
            _transfer(from, to, tokenId);
        }
    }


    function isOwnerOrZeroOrAuth(address _sender, address _addr) internal view returns (bool) {
        return _sender == owner() || _addr == address(0) || isTimeweaver(_sender);
    }

    function withdrawFunds() external onlyTimeweaver nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        if (!success) {
            revert FailedTransfer();
        }
    }

    function TimeWarp(uint256[] calldata _tokenIds) external onlyTimeweaver {
        for (uint256 i = 0; i < _tokenIds.length; ++i) {
            _burn(_tokenIds[i]);
        }
    }

    // The following functions are overrides required by Solidity.
  function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

}



