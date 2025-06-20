// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";  // ✅ Use proper interface

contract NFTRental {
    struct Rental {
        address owner;
        address renter;
        address nftAddress;
        uint256 tokenId;
        uint256 startTime;
        uint256 duration;
        uint256 fee;
        bool isActive;
    }

    uint256 public rentalCounter;
    mapping(uint256 => Rental) public rentals;

    event NFTListed(uint256 indexed rentalId, address indexed owner, address nftAddress, uint256 tokenId, uint256 fee, uint256 duration);
    event NFTRented(uint256 indexed rentalId, address indexed renter);
    event NFTReturned(uint256 indexed rentalId);

    function listNFT(address _nftAddress, uint256 _tokenId, uint256 _fee, uint256 _duration) external {
        IERC721(_nftAddress).safeTransferFrom(msg.sender, address(this), _tokenId);

        rentals[rentalCounter] = Rental({
            owner: msg.sender,
            renter: address(0),
            nftAddress: _nftAddress,
            tokenId: _tokenId,
            startTime: 0,
            duration: _duration,
            fee: _fee,
            isActive: true
        });

        emit NFTListed(rentalCounter, msg.sender, _nftAddress, _tokenId, _fee, _duration);
        rentalCounter++;
    }

    function rentNFT(uint256 _rentalId) external payable {
        Rental storage rental = rentals[_rentalId];
        require(rental.isActive, "Rental not active");
        require(rental.renter == address(0), "Already rented");
        require(msg.value >= rental.fee, "Insufficient fee");

        rental.renter = msg.sender;
        rental.startTime = block.timestamp;

        emit NFTRented(_rentalId, msg.sender);
    }

    function returnNFT(uint256 _rentalId) external {
        Rental storage rental = rentals[_rentalId];
        require(msg.sender == rental.renter, "Not the renter");
        require(block.timestamp >= rental.startTime + rental.duration, "Rental period not over");

        IERC721(rental.nftAddress).safeTransferFrom(address(this), rental.owner, rental.tokenId);
        rental.isActive = false;

        payable(rental.owner).transfer(rental.fee);

        emit NFTReturned(_rentalId);
    }
}
