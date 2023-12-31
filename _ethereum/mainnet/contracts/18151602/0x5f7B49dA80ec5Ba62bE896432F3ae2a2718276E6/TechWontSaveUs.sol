// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10 <0.9.0;

// #&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&##&&&&&&&#&&&&#&&&&&&&&&&&&&&&&#&&&&&&#&&&&&@&&&&&##&&#&
// &&&&@&&&&&#&&#&&&#&&&&&&#&#&&##&&&&#&&##&#&&&&&&#&&&&&#&&#&&&&&&&&&&&#&&&&&###&&&&#&&#&&&&&&&&&#&#&#
// &&&#&&#&&#&&&#&&&&&&&&&#&&&&&&&#&&#####&&##&&#&&&#&#&&#&&&&&&&&&&&&&&#&&&&&&#&&&&#&#&#&&##&&&&&&&&&#
// #&&&&#&&&&&&&&&&#&#&&#&&#&&&&&&&&##&&&&&####&#&&##&#&&&&&#&&#&&&&&&&###&&&&&#&&&&&@&&&&&&&&&&#&&&&&#
// &&&&&&&&&&&&&&&&#&&&&&#&&#@##B5&&&&@&&&&&@&@@&&@&&&#&&&&&&&@&&&&&#&&&&#&#&&&##&&@&&&&&&&#&&&&&&&&&&&
// ##&&&#&&##&##&&##&&&&&##&&&&&Y7GBGGGGGGPGGGPGGGGBB&&&&&#&&&&&&&&#&#&#&&&&&&&&&&&&&&&&&&&&&&&#&&&&#&#
// #&@&&&##&#&&#&&#&&##&&&&##&&&Y7Y55J!!!!!!!!!!!!!7?G&&&&#&&&&&&&&&&&&&&&&&&&&&&&&&&&&#&&&@&&&&&&&&&&&
// &&&&&&&#&&#&&&&&#&#&&#&&&#&@@J!!!!!!!!!!!!!!!!!!!!!5P5B&#######&#5YYYJJYYJ5G&5JJYYJ#&#&@&&&&&&&#&&##
// &@&#&&#&&&#&&&&&&&&###&PGG555?!!!!!!!!!!!!!!!!!!!!!!!!7777?777777!!!!?555YPB#!!!!!!G&&&&&&@#&&&&&&&&
// &&&&&#&&&##&&&&###&P7?P75?!!!7!!!!!!!!!!!!!!7!!!!!!!!!!!!!!!!!!!!!!!!YGYB&&BY!!?GB#&#&&&&&&&&&&##&&#
// &&&&&&####&&&&&&5?77!!~!77!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!~7??7!!!J&&&@&&&&&#&#&&&&####
// &&&&&&&&&#&&#&&&&5?JY557!!!!!!!!!!!!!!!!!7!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!75&&&&&&&&&&&&@&&&#&&@
// &&&&&&&&&&&&##&&&J!J&&B?!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!7!!!!!!!!!!!!!!7!?&&&&&#&#@&@&#&&&#&&&
// &&&&&#&#&&&&&&&#&J~J&&P7!!!!7!!!!!!7!!!!!!!!!!!!!!!!!!!!!!!!7!!!!!!!!!!!!!!!!!!?#&&@#&&&&&&&&&&&&&#@
// ##&&&&&###GPPB#&&J!Y&&?!!!!!!7!!!!!!!!7!!!!!!!!!!7!!!!!7!!!!!!!!!!!!!!!!!!!!!!!!?#&BBGB&###&&&&#&#&&
// @@&&&&#&&#55Y5555?!7JJ7!!!!!!!!!!!!!!!!!!!!!!!!!!7!!!7!!!!!!!!!!!7!!!!!!!!!!!!!!!PG7!!5@&#&&&&@#&&#&
// &##&&&#&&&&&&&&Y~!!!!!!7!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!JG&&#&&#&&&&#&
// &&#&&&&&&#&&&#P57!7!!!!!!!!!!!!!!!!!!!7!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!?&&&&&&##&&&#
// &&#&&&&&#&&&&#P?!!!!!!77!!!!!!!!!!!!!!!!!!!!!!!!!!7!!!!!!!??7777!!!!!!!!!!!!!!!!!!!!!!!!?#@#&&&&&@&&
// &&&&&&#&&&&#&&&5!!!!!!!!!!!!!!!!!!!!!7??!!7!!!!!!!!!!!!??J#B?777!7J???!!!!!!!!!!!!!!!!7!!PB&&&&#&&&&
// #&&#&&&&&#&##&&#?!!!!!!!!!!!!!!!!!!!J#@#5P&5!!!!!!!?JYG&&&&BYJJJJB@&#&J7??!!!!!!!!!!!!!7GPG&&@&&&#&&
// &&#&&&&&&#&&&&&&P!!!!!!!!!!!!!!7?PPP#&&#&&@P!!!!!!!G&&&##&&#&&&#&@&#&&5#&G~??!!!!!!!!!!?&&@&&&&&&&&&
// &##&&&&&&&&&#&&&?!!!!!!!!!!!!!!P&&&&&&##&&&P!!!!!!!G&#&&&&&&&&&&&&&&&#?B@B5BP!!77!!!!!!?#&&&####&&&&
// ####&&&&&&&&&##&BJJ7!!!!!!!5BBB#&&&#&&#&&&#Y!!!!!!!G&&#&@&&&&&&&&&&&&#B#&&J?7!!!!!!!!!!J&&&&##&&&&&&
// &&&&&#&#&&#&&&&#&&P!!!!!!!!G@&&&&&&&&&&&&&BBBJ!!!!!7G&&&&&&&##&&&&&&&&&P557!!!!7!!?J??!?#&&#&&&&@&&&
// &&&&&&#&&&&&&&&&&&#5!!!!!!!G#B&@&##&&&&&&&&&@JYJ!!!!?Y#&&&&&###@&@&@@#&J!!!!!!!!!!?B@&B#&&&&&&#&#&&#
// &&&#&###&#&&&&&&&&&P!!!!!!!PY?JY55#&#BJY5GBBG5#P!!!!!!GBB#@&&&#55555#&@Y!!!!!J5GBBB###&&&&&@&&&&&##&
// &&#&&&&#&&#&&#&##&&P!!!!!!!77!!7###&&B7Y#?P&?77!!!!!!!!!7Y5555J!!!!!Y5P?!!!!!?YJ5&&&&&&#&#&&&&&&##&&
// #&&&&&&&&&&&#&&&#&&5!!!!!7!!!!!7&&&&&#BGJ!?J!!!!!!!!!!!!!!!!!!!!!!!!!!~!!!!JPGY??&&&#&&&&&&##&&&&&&&
// &&&&#&&&&&&&&&&&&&&#?!!!!!!7!!!7J5B&&BJ?!!!!?P5J!?5555!!!!!!!!!!!!!!7555YPB#&&&#&&&&&&&&###&&&&#&&&&
// &&&&&&&&#&@&###&&#&&BG7!!!!!!!!!!!P577!!!!!!J&J?!G&&&&J7!!!!!77!!!!!?@&&@@@&&#&&&&&&&&&&&#&&#&&@&###
// &&&&&&&&&&&&&#&&&&&&#&5J!!!!!!!!!!!!!!!!!!!!?##BP#&&&&#J!!!!!!!!!!!!J&&&&&&&&&###&&&&#&##&&&&#&&&&&&
// &##&&&&&&&&&&&&&&&&&&#&@Y!!!!!!!!7!!!!!!!!!!J&#&&&&&GP##B!!!!!!!!!JG#&#####&#&&##&&&&&&&#&#&&&#&#&&&
// ##&&&&&&@&&&&#&@&&&#&#JJJ!!!!!!!7!!!!!7!!!!!J#Y##GP?7!P&&7!!!!!!!JB#&&#&##&#&&&&&#&&&##&&##&&&&&&&&#
// &&#&###&&&&&&&&&&&#&&&G?5?77777!!!!!!!!7!!!!?G777!!!!!7557!!7!!!!JGB&&&&#&&&&&&&&&#&&&&&&#&&&&#&&#&&
// &#&&&&&#&@&&&&&#&&#&&#&B&######Y7!7?7!!!?JJ7!!!!!!!!!!!!!!!!!!!!!7JG@&&&&#&&&&&&&@&#&&&&#&&##&&&&&&#
// &&&&&&&&&&&&&&&&&&#&&&#&@&#&&&#&BJG&GJJ?5&#Y!!!!??!!!!!!!!!777!!!J@&&&&&&&&@&#&&&&#&&##&&&&&&&#&#&&@
// #&##&&&#&##&#&&&&&&&&&#&&&&&#&&&&&&&&#&&#&PY?!!!5P!!!!7777!!!!JG?J&&###&#&&&&#&&&##&&#&@&##&&&&&&&&&
// &&#&#&&&&&#&&&&&&@&&&@&&&#&&&@&&&###&&##&&B?!!!!5P!!!!?#&G7!!!Y@##&&&&&&&&&&#&&&##&&&&&&&&&&&&&&#&&&
// &&&&&&&&&&&&#&&&&&&&#&&&##&&#&&&&&&&&&@&&&@Y!!!!5P!??~?&&P!!!!5&#&&&&#&&&&&&&&&&&&&&&&&&&&&#&&&&#&##
// &&&&#&##&&&&&#&&&&&#&&&&&&&&&&&&&&&#&&&&&&GJ?!!!5P!5#5G&&B?J5B#&&#&&&&&&&&#&&&@&&##&&&&&&&&&&#&@&&&&
// &&&##&#&&##&&&##@&#&&&&&&&#&&&&&&&@&##&&#&JYG!!!5P~Y@&&##&##&&&#&#&&##&&#&&&#&&#&&#&#&&&&&@##&#&#&&&
// #&&&&&&&&&##&&&&&###&&&&&#&&&&&&&&&&&&######BJYB#B5G&&&&&&&&##&&&&&#&&#&&&&&&#&#&&###&&&&#&&&&#&&&&&
// &####&&#&&&&&&&&&#&&&&&&&#&&&&&&&#&&&&#&&&&#&&&&#&&&&&&&##&&&&&&#&&&##&&@&#&&#&&&#&#&#&#####&@&#&&&&
// #&&&&###&&&#&&&&&&&&&&&##&&&&&&&&&###&&&&&&#&@&&&&&&&#&&&&&&&&&&#&&&&&&&&&##&&&&&&&&&&&&&&#&&&&&&&#&
// #&&&#&&&&&&&&&&&&&&&&&#&&&##&&&&&&&&#&&&&&&&&&&&&&#&&&##&&#&&#&#&&#&#&&&&&#&&&&&&&###&&&##&#&&#&#&&&
// ##&&&#&&&&@@&&&&&&#&&##&&&&&&&&&&&&&##&@&#&&&&&&#&#&###&&&&#&&#&&&&&&&#&&&#&&&&&#&&&#&&&#&&#&##&#&&&

import "./ERC721ACommon.sol";
import "./BaseTokenURI.sol";
import "./ERC2981.sol";
import "./ITokenDescriptor.sol";

address constant THE_DOOMED_DAO = 0xD8D157A111e42E93Ad72ddC68930Ca72a3d814a0;

// @author the doomed dao
contract TechWontSaveUs is
    ERC721ACommon,
    BaseTokenURI
{
    ITokenDescriptor public descriptorContract;

     /**
     * @notice Specify the descriptor contract.
     * @dev Only callable by the steering role.
     */
    function setTokenDescriptorAddress(address descriptorAddress)
        public
        onlyRole(DEFAULT_STEERING_ROLE)
    {
        descriptorContract = ITokenDescriptor(descriptorAddress);
    }

    /*
    * #notice Grants a steering role.
    * @dev Only callable by the steering role.
    */
    function grantSteeringRole(address addressToGrant)
        public
        onlyRole(DEFAULT_STEERING_ROLE)
    {
        _grantRole(DEFAULT_STEERING_ROLE, addressToGrant);
    }

    /*
    * #notice Revokes a steering role.
    * @dev Only callable by the steering role.
    */
    function revokeSteeringRole(address addressToRevoke)
        public
        onlyRole(DEFAULT_STEERING_ROLE)
    {
        require(addressToRevoke != THE_DOOMED_DAO, "Can't revoke The Doomed DAO");
        _revokeRole(DEFAULT_STEERING_ROLE, addressToRevoke);
    }

    /**
     * @notice Construct a new TechWontSaveUs contract.
     * @param steerers The addresses of the steerers.
     * @param royaltyReceiver The address of the royalty receiver.
     * @param royaltyBasisPoints The royalty basis points.
     */
    constructor(
        address[] memory steerers,
        address payable royaltyReceiver,
        uint96 royaltyBasisPoints
    ) ERC721ACommon(THE_DOOMED_DAO, THE_DOOMED_DAO, "TechWontSaveUs", "TECHWONTSAVEUS", royaltyReceiver, royaltyBasisPoints)
      BaseTokenURI("") {
        for (uint256 i = 0; i < steerers.length; i++) {
            _grantRole(DEFAULT_STEERING_ROLE, steerers[i]);
        }
    }

    /**
     * @notice Returns the base token URI.
     */
    function _baseURI()
        internal
        view
        override(BaseTokenURI, ERC721A)
        returns (string memory)
    {
        return BaseTokenURI._baseURI();
    }

    /**
     * @notice Mint a new token to The Doomed DAO.
     * @dev Only callable by the steering role.
     */
    function mint(
        uint256 quantity
    ) public onlyRole(DEFAULT_STEERING_ROLE) {
        _safeMint(THE_DOOMED_DAO, quantity, '');
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721ACommon, AccessControlEnumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Token must exist");

        if (address(descriptorContract) != address(0)) {
            return descriptorContract.tokenURI(tokenId);
        }
        return super.tokenURI(tokenId);
    }

}
