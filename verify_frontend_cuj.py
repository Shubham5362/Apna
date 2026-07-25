import os
import sys
from playwright.sync_api import sync_playwright

def run_cuj():
    os.makedirs("verification/screenshots", exist_ok=True)
    os.makedirs("verification/videos", exist_ok=True)

    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        # Use new_context for video recording
        context = browser.new_context(
            record_video_dir="verification/videos",
            viewport={"width": 1280, "height": 800}
        )
        page = context.new_page()
        try:
            # Step 1: Health Monitor / Dashboard
            print("Navigating to http://localhost:3000 ...")
            page.goto("http://localhost:3000")
            page.wait_for_timeout(3000)

            # Step 2: Navigate to Login screen
            print("Navigating to Login screen (http://localhost:3000/#/login) ...")
            page.goto("http://localhost:3000/#/login")
            page.wait_for_timeout(8000)  # wait for CanvasKit & fonts to load

            print("Capturing Login screen screenshot...")
            page.screenshot(path="verification/screenshots/login_screen.png")
            print("Screenshot saved to verification/screenshots/login_screen.png")

            # Step 3: Back to Health Dashboard
            print("Navigating back to Health Dashboard...")
            page.goto("http://localhost:3000")
            page.wait_for_timeout(5000)

            print("Capturing health dashboard screenshot...")
            page.screenshot(path="verification/screenshots/dashboard.png")
            print("Screenshot saved to verification/screenshots/dashboard.png")

            page.wait_for_timeout(1000)  # hold final state for the video

        except Exception as e:
            print(f"Error during CUJ: {e}")
            sys.exit(1)
        finally:
            context.close()  # MUST close context to save video
            browser.close()
            print("Verification CUJ completed.")

if __name__ == "__main__":
    run_cuj()
