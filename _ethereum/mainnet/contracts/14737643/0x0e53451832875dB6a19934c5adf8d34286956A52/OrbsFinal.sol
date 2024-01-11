// SPDX-License-Identifier: MIT

// Wavelengthbykaleb.com. Art by @Kalebscode, Contract and website by @georgefatlion. Implementation based on the awesome ERC721A contract from AZUKI.
// __          __                 _                      _    _        ____         _
// \ \        / /                | |                    | |  | |      / __ \       | |
//  \ \  /\  / /__ _ __   __ ___ | |  ___  _ __    __ _ | |_ | |__   | |  | | _ __ | |__   ___
//   \ \/  \/ // _` |\ \ / // _ \| | / _ \| '_ \  / _` || __|| '_ \  | |  | || '__|| '_ \ / __|
//    \  /\  /| (_| | \ V /|  __/| ||  __/| | | || (_| || |_ | | | | | |__| || |   | |_) |\__ \
//     \/  \/  \__,_|  \_/  \___||_| \___||_| |_| \__, | \__||_| |_|  \____/ |_|   |_.__/ |___/
//                                                 __/ |
//                                                |___/
//  _              _  __       _        _            _         _                  _
// | |            | |/ /      | |      | |          | |       | |                | |
// | |__   _   _  | ' /  __ _ | |  ___ | |__        | |  ___  | |__   _ __   ___ | |_  ___   _ __
// | '_ \ | | | | |  <  / _` || | / _ \| '_ \   _   | | / _ \ | '_ \ | '_ \ / __|| __|/ _ \ | '_ \
// | |_) || |_| | | . \| (_| || ||  __/| |_) | | |__| || (_) || | | || | | |\__ \| |_| (_) || | | |
// |_.__/  \__, | |_|\_\\__,_||_| \___||_.__/   \____/  \___/ |_| |_||_| |_||___/ \__|\___/ |_| |_|
//          __/ |
//         |___/

pragma solidity ^0.8.4;
import "./ERC721A.sol";
import "./Ownable.sol";
import "./Strings.sol";

// Interface for original Wavelength contract.
interface Wavelength {
    function ownerOf(uint256) external view returns (address);

    function totalSupply() external view returns (uint256);

    function balanceOf(address) external view returns (uint256);

    function tokenOfOwnerByIndex(address, uint256)
        external
        view
        returns (uint256);
}

contract ORBS is ERC721A, Ownable {
    constructor() ERC721A("Orbs", "ORBS") {}

    /* ========== STATE VARIABLES ========== */

    uint256 private constant MAX_SUPPLY = 1141;
    address private wavelengthContractAddr;
    mapping(uint256 => bool) private claimed;
    bool private claimOpen;
    string private baseTokenURI;
    string private contracturi;

    /* ========== VIEWS ========== */

    /**
     * @notice Get the claim open state.
     *
     */
    function getClaimState() public view returns (bool) {
        return claimOpen;
    }

    /**
     * @notice Get the claim status for a tokenID.
     *
     * @param _tokenID.
     */
    function getTokenStatus(uint256 _tokenID) public view returns (bool) {
        return claimed[_tokenID];
    }

    /**
     * @notice Return a comma seperated string with the token IDs that are still to be claimed, for a given address.
     *
     * @param _addr the address to check tokens for.
     */
    function getUnclaimedTokens(address _addr)
        public
        view
        returns (string memory)
    {
        uint256 totalWavelengths = Wavelength(wavelengthContractAddr).balanceOf(
            _addr
        );
        string memory unclaimedTokens;

        for (uint256 x = 0; x < totalWavelengths; x++) {
            uint256 tokenNo = Wavelength(wavelengthContractAddr)
                .tokenOfOwnerByIndex(_addr, x);
            if (!claimed[tokenNo]) {
                unclaimedTokens = string(
                    abi.encodePacked(
                        unclaimedTokens,
                        Strings.toString(tokenNo),
                        ","
                    )
                );
            }
        }
        return unclaimedTokens;
    }

    /**
     * @notice Return the contractURI
     */
    function contractURI() public view returns (string memory) {
        return contracturi;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * @notice Mint an orbs. The total number to mint is defiend by the length of the array of Wavelength tokenIDs passed in.
     *
     * @param _tokenIDs the tokensToClaim.
     */
    function mintOrb(uint256[] memory _tokenIDs) public {
        // check the claim is open
        require(claimOpen, "Claim is not open");

        // Loop through all token IDs and check the caller owns the corresponding Wavelength and that is has not been claimed already.
        for (uint256 x = 0; x < _tokenIDs.length; x++) {
            require(
                Wavelength(wavelengthContractAddr).ownerOf(_tokenIDs[x]) ==
                    msg.sender,
                "don't own"
            );
            require(!claimed[_tokenIDs[x]], "already claimed");

            // Set the token claim status to true.
            claimed[_tokenIDs[x]] = true;
        }
        // Stop contracts calling the method.
        require(tx.origin == msg.sender);

        // Check the amount isn't over the max supply.
        require(
            totalSupply() + _tokenIDs.length <= MAX_SUPPLY,
            "Surpasses supply"
        );

        // Safemint a number of tokens equal to the length of the tokenIDs array.
        _safeMint(msg.sender, _tokenIDs.length);
    }


    /* ========== RESTRICTED FUNCTIONS ========== */

    /**
     * @notice Update the address used to interface with the Wavelength contract.
     *
     * @param _newAddress the new address for the Wavelength contract.
     */
    function setWavelengthAddress(address _newAddress) external onlyOwner {
        wavelengthContractAddr = _newAddress;
    }

    /**
     * @notice Set the claim open state.
     *
     * @param _claimState.
     */
    function setClaimState(bool _claimState) external onlyOwner {
        claimOpen = _claimState;
    }

    /**
     * @notice Reset the claimed state of a given token number.
     *
     * @param _tokenID the token to update.
     * @param _claimState the state to set.
     */
    function resetClaimed(uint256 _tokenID, bool _claimState) external onlyOwner {
        claimed[_tokenID] = _claimState;
    }

    /**
     * @notice Admin mint, to allow direct minting of the 1/1s.
     *
     * @param _recipient the address to mint to.
     * @param _quantity the quantity to mint.
     */
    function mintAdmin(address _recipient, uint256 _quantity) public onlyOwner {
        // Check the amount isn't over the max supply.
        require(totalSupply() + _quantity <= MAX_SUPPLY, "Surpasses supply");

        // Safemint the quantiy of tokens to the recipient.
        _safeMint(_recipient, _quantity);
    }

    /**
     * @notice Change the contract URI
     *
     * @param _uri the respective base URI
     */
    function setContractURI(string memory _uri) external onlyOwner {
        contracturi = _uri;
    }

    /**
     * @notice Change the base URI for returning metadata
     *
     * @param _baseTokenURI the respective base URI
     */
    function setBaseURI(string memory _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    /* ========== OVERRIDES ========== */

    /**
     * @notice Return the baseTokenURI
     */
    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }
}
