# Win My Arguments - iOS App Workflow

## 1. App Feature Description
### Topic Input
- **Functionality**: Users enter a debate or argument topic via a text input field.
- **Implementation**: Utilize a simple text field with a search button to initiate the fact retrieval process.

### Fact Retrieval
- **Functionality**: The app retrieves facts from reliable internet sources based on the input topic.
- **Implementation**: Integrate with APIs that provide factual information and data verification.

### Reference Generation
- **Functionality**: Provide citations or direct links for each fact presented.
- **Implementation**: Each fact card will have a 'source' link that users can tap to view the original source.

### Fact Verification
- **Functionality**: Enhance reliability by cross-verifying facts through multiple sources.
- **Implementation**: Use multiple APIs and display a verification status indicator.

### User History
- **Functionality**: Allow users to view and revisit their past search queries and results.
- **Implementation**: Implement a history tracking system that stores user queries and the corresponding results.

### Sharing Options
- **Functionality**: Enable users to share facts and sources via social media or other communication tools.
- **Implementation**: Incorporate native iOS sharing functionality to allow dissemination of information easily.

## 2. App Interface Description
### Home Screen
- **Elements**: Search bar, app logo, and a navigation menu.
- **Style**: Clean and professional with an emphasis on usability.

### Results Screen
- **Elements**: Cards containing facts with expandable sections for details and source links.
- **Style**: Information is presented in a digestible format, using cards for easy reading.

### History Page
- **Elements**: A list or timeline view of past searches with a summary of the results.
- **Style**: Simple and easy to navigate, with quick access to redo a search.

### Settings Page
- **Elements**: Options for source preferences, notification settings, and app theme.
- **Style**: User-friendly with clear categorization of settings.

## 3. Relevant Documentation/Links for References
### Swift and iOS Development
- [Swift Official Documentation](https://swift.org/documentation/)
- [Apple's iOS Human Interface Guidelines](https://developer.apple.com/design/)

### APIs for Fact Checking
- [Google Fact Check Tools API](https://developers.google.com/fact-check/tools/api/)
- [Media Bias/Fact Check API](https://mediabiasfactcheck.com/api/)

### Web Scraping (for server-side operations)
- [Beautiful Soup Documentation](https://www.crummy.com/software/BeautifulSoup/bs4/doc/)
- [Scrapy Official Site](https://scrapy.org/)

## 4. Different Pages for the Application
### Home Page
- **Purpose**: Entry point for users to input their debate topics.
- **Features**: Text input, search button, navigation to history and settings.

### Facts Display Page
- **Purpose**: Show search results with factual information and sources.
- **Features**: Cards layout for each fact, expandable for more details and source verification.

### History Page
- **Purpose**: Allow users to view and manage their search history.
- **Features**: List of past searches, option to re-run searches.

### Settings/Preferences Page
- **Purpose**: Manage app settings and preferences.
- **Features**: Toggle source preferences, manage notification settings, choose app themes.