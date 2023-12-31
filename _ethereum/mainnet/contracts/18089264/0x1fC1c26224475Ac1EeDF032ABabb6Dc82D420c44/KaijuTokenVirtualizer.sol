// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "./Ownable.sol";

import "./IRWaste.sol";
import "./IScales.sol";

error KaijuTokenVirtualizer_UninitializedDestination();

/**
                        .             :++-
                       *##-          +####*          -##+
                       *####-      :%######%.      -%###*
                       *######:   =##########=   .######*
                       *#######*-#############*-*#######*
                       *################################*
                       *################################*
                       *################################*
                       *################################*
                       *################################*
                       :*******************************+.

                .:.
               *###%*=:
              .##########+-.
              +###############=:
              %##################%+
             =######################
             -######################++++++++++++++++++=-:
              =###########################################*:
               =#############################################.
  +####%#*+=-:. -#############################################:
  %############################################################=
  %##############################################################
  %##############################################################%=----::.
  %#######################################################################%:
  %##########################################+:    :+%#######################:
  *########################################*          *#######################
   -%######################################            %######################
     -%###################################%            #######################
       =###################################-          :#######################
     ....+##################################*.      .+########################
  +###########################################%*++*%##########################
  %#########################################################################*.
  %#######################################################################+
  ########################################################################-
  *#######################################################################-
  .######################################################################%.
     :+#################################################################-
         :=#####################################################:.....
             :--:.:##############################################+
   ::             +###############################################%-
  ####%+-.        %##################################################.
  %#######%*-.   :###################################################%
  %###########%*=*####################################################=
  %####################################################################
  %####################################################################+
  %#####################################################################.
  %#####################################################################%
  %######################################################################-
  .+*********************************************************************.
 * @title Kaiju Token Virtualizer
 * @notice Burn Kaiju ecosystem tokens to virtualize them to a destination
 * @author Augminted Labs, LLC
 */
contract KaijuTokenVirtualizer is Ownable {
    event Virtualize(
        address indexed token,
        address indexed from,
        uint256 indexed destination,
        uint256 amount
    );

    IRWaste public rwaste;
    IScales public scales;
    mapping(uint256 => string) public destinations;

    mapping(address => mapping(uint256 => uint256)) internal _rwasteVirtualized;
    mapping(address => mapping(uint256 => uint256)) internal _scalesVirtualized;

    constructor(
        address _rwaste,
        address _scales,
        address _owner
    ) {
        rwaste = IRWaste(_rwaste);
        scales = IScales(_scales);

        transferOwnership(_owner);
    }

    /**
     * @notice Modifier that ensures the specified destination has been initialized
     * @param _destination Destination to validate
     */
    modifier validateDestination(uint256 _destination) {
        if (bytes(destinations[_destination]).length == 0) revert KaijuTokenVirtualizer_UninitializedDestination();
        _;
    }

    /**
     * @notice Returns the amount of $RWASTE virtualized by a specified address for a specified destination
     * @param _from Address to return the amount of virtualized $RWASTE for
     * @param _destination Destination to return the amount of virtualized $RWASTE for
     * @return uint256 Amount of $RWASTE virtualized by the address to the specified destination
     */
    function rwasteVirtualized(address _from, uint256 _destination) public view returns (uint256) {
        return _rwasteVirtualized[_from][_destination];
    }

    /**
     * @notice Returns the amount of $SCALES virtualized by a specified address for a specified destination
     * @param _from Address to return the amount of virtualized $SCALES for
     * @param _destination Destination to return the amount of virtualized $SCALES for
     * @return uint256 Amount of $SCALES virtualized by the address to the specified destination
     */
    function scalesVirtualized(address _from, uint256 _destination) public view returns (uint256) {
        return _scalesVirtualized[_from][_destination];
    }

    /**
     * @notice Set the $RWASTE token contract
     * @param _rwaste New $RWASTE token contract
     */
    function setRWaste(address _rwaste) public payable onlyOwner {
        rwaste = IRWaste(_rwaste);
    }

    /**
     * @notice Set the $SCALES token contract
     * @param _scales New $SCALES token contract
     */
    function setScales(address _scales) public payable onlyOwner {
        scales = IScales(_scales);
    }

    /**
     * @notice Set the values of a destination
     * @param _id Identifier of the destination
     * @param _name Name of the destination
     */
    function setDestination(uint256 _id, string calldata _name) public payable onlyOwner {
        destinations[_id] = _name;
    }

    /**
     * @notice Virtualize $RWASTE to a specified destination
     * @param _amount Amount of $RWASTE to virtualize
     * @param _destination Destination to virtualize $RWASTE to
     */
    function virtualizeRWaste(uint256 _amount, uint256 _destination) public validateDestination(_destination) {
        rwaste.burn(msg.sender, _amount);

        unchecked { _rwasteVirtualized[msg.sender][_destination] += _amount; }

        emit Virtualize(
            address(rwaste),
            msg.sender,
            _destination,
            _amount
        );
    }

    /**
     * @notice Virtualize $SCALES to a specified destination
     * @param _amount Amount of $SCALES to virtualize
     * @param _destination Destination to virtualize $SCALES to
     */
    function virtualizeScales(uint256 _amount, uint256 _destination) public validateDestination(_destination) {
        scales.spend(msg.sender, _amount);

        unchecked { _scalesVirtualized[msg.sender][_destination] += _amount; }

        emit Virtualize(
            address(scales),
            msg.sender,
            _destination,
            _amount
        );
    }
}