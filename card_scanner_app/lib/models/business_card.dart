    // This class defines the structure of our business card data.
    class BusinessCard {
      // These are the fields that will hold the data from the scanned card.
      String name;
      String organization;
      String designation;
      String contact; // This will hold the phone number
      String email;
      String website;
      String address;
      String remarks;

      // This is the constructor. It sets default empty values when a new card is created.
      BusinessCard({
        this.name = '',
        this.organization = '',
        this.designation = '',
        this.contact = '',
        this.email = '',
        this.website = '',
        this.address = '',
        this.remarks = '',
      });

      // This is a special constructor that creates a BusinessCard object
      // from the JSON data that our Python backend sends us.
      // The keys like 'name', 'organization' MUST match the keys in the JSON.
      factory BusinessCard.fromJson(Map<String, dynamic> json) {
        return BusinessCard(
          name: json['name'] ?? '',
          organization: json['organization'] ?? '',
          designation: json['designation'] ?? '',
          contact: json['contact'] ?? '',
          email: json['email'] ?? '',
          website: json['website'] ?? '',
          address: json['address'] ?? '',
          // Remarks are not sent from the backend, so we don't look for them here.
        );
      }

      // This method converts our BusinessCard object back into JSON format,
      // which is needed when we send the final data to our '/save-contact' endpoint.
      Map<String, dynamic> toJson() {
        return {
          'name': name,
          'organization': organization,
          'designation': designation,
          'contact': contact,
          'email': email,
          'website': website,
          'address': address,
          'remarks': remarks,
        };
      }
    }
    
