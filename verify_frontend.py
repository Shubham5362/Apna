import os
from playwright.sync_api import sync_playwright

def run():
    # Ensure folders exist
    os.makedirs("/home/jules/verification/screenshots", exist_ok=True)
    os.makedirs("/home/jules/verification/videos", exist_ok=True)

    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        context = browser.new_context(
            record_video_dir="/home/jules/verification/videos",
            viewport={"width": 1280, "height": 800}
        )
        page = context.new_page()
        try:
            print("Navigating to local Flutter app server on http://localhost:3000...")
            page.goto("http://localhost:3000")

            print("Waiting for Flutter Web/CanvasKit engine compilation and initialization...")
            # Flutter Web takes a few seconds to boot CanvasKit and render the main tree.
            page.wait_for_timeout(10000)

            print("Capturing health dashboard screenshot...")
            page.screenshot(path="/home/jules/verification/screenshots/verification.png")
            print("Screenshot saved to /home/jules/verification/screenshots/verification.png")

            page.wait_for_timeout(2000)  # Extra padding for video
        except Exception as e:
            print(f"Error occurred during visual verification: {e}")
        finally:
            context.close()
            browser.close()
            print("Browser closed.")

if __name__ == "__main__":
    run()
