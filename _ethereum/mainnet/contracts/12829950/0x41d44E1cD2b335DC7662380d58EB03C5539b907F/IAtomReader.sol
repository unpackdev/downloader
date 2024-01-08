//SPDX-License-Identifier: Licence to thrill
pragma solidity ^0.8.0;

/// @title POWNFT Atom Reader
/// @author AnAllergyToAnalogy
/// @notice On-chain calculation atomic number and ionisation data about POWNFT Atoms. Replicates functionality done off-chain for metadata.
interface IAtomReader{

    /// @notice Get atomic number and ionic charge of a specified POWNFT Atom
    /// @dev Gets Atom hash from POWNFT contract, so will throw for _tokenId of non-existent token.
    /// @param _tokenId TokenId of the Atom to query
    /// @return atomicNumber Atomic number of the Atom
    /// @return ionCharge Ionic charge of the Atom
    function getAtomData(uint _tokenId) external view returns(uint atomicNumber, int8 ionCharge);

    /// @notice Get atomic number of a specified POWNFT Atom
    /// @dev Gets Atom hash from POWNFT contract, so will throw for _tokenId of non-existent token.
    /// @param _tokenId TokenId of the Atom to query
    /// @return Atomic number of the Atom
    function getAtomicNumber(uint _tokenId) external view returns(uint);

    /// @notice Get ionic charge of a specified POWNFT Atom
    /// @dev Gets Atom hash from POWNFT contract, so will throw for _tokenId of non-existent token.
    /// @param _tokenId TokenId of the Atom to query
    /// @return ionic charge of the Atom
    function getIonCharge(uint _tokenId) external view returns(int8);

    /// @notice Get array of all possible ions for a specified element
    /// @param atomicNumber Atomic number of element to query
    /// @return Array of possible ionic charges
    function getIons(uint atomicNumber) external pure returns(int8[] memory);

    /// @notice Check if a given element can have a particular ionic charge
    /// @param atomicNumber Atomic number of element to query
    /// @param ionCharge Ionic charge to check
    /// @return True if this element can have this ion, false otherwise.
    function isValidIonCharge(uint atomicNumber, int8 ionCharge) external pure returns(bool);

    /// @notice Check if a given element has any potential ions
    /// @param atomicNumber Atomic number of element to query
    /// @return True if this element can ionise, false otherwise.
    function canIonise(uint atomicNumber) external pure returns(bool);
}