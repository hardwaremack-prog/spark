SPARK  -  offline voice chat for an RTX 3050 PC
=================================================

Talk to your own AI through a headset. Spark listens, thinks and talks back,
all on this computer. After setup it works with no internet at all.

  Ears   : Whisper (small.en) on the CPU - the 10-core Xeon handles it easily
  Brain  : Ollama on the RTX 3050 graphics card
             gemma3:4b   - main brain, smart and quick (default)
             llama3.2:3b - fastest replies
  Voice  : Piper (Ryan, Lessac, Cori, Joe)


SETUP (once, needs internet)
----------------------------
1. Install the latest NVIDIA driver for the RTX 3050 (nvidia.com/drivers)
   if it isn't already.
2. Unzip this folder somewhere permanent, e.g.  C:\Apps\Spark
3. Double-click  "Install Spark.bat"
   - installs Python 3.12 and Ollama if needed
   - downloads voices, speech recognizer and two AI models (~8 GB)
   - adds "Spark" and "Update Spark" to the desktop and Start menu
4. Done. You can go offline now.


USING IT
--------
Double-click "Spark". It opens in its own window. Click "Start talking"
and allow the microphone.

  Push to talk : hold SPACE (or hold the button), talk, let go
  Hands-free   : just talk; Spark answers when you pause
                 (talk over a reply to interrupt it)
  Esc          : stop the current reply
  Typing       : the text box works too

The gear menu picks the headset, voice, speed, Hands-free sensitivity and
Spark's personality. The model picker at the top switches brains; Spark
says when the switch is done, and each reply shows which model answered.

Want to try a bigger brain? 6 GB of graphics memory fits up to about a
7-8 billion parameter model. In a terminal:   ollama pull qwen2.5:7b
then pick it in the model picker (smarter, a little slower).


GETTING UPDATES
---------------
When the PC is online, Spark checks for a new version on start and shows
an "Update available" button at the top. Any of these updates it:
  1. Gear menu -> Updates -> "Update now"
  2. The "Update Spark" icon on the desktop
  3. Double-click "Update Spark.bat" in this folder
Models, voices, settings, chats and config.json changes are kept.
If Spark is open it restarts by itself and the window reloads.


IF SOMETHING ISN'T WORKING
--------------------------
The dots at the top (Brain / Ears / Voice) go green when ready.
  Brain red   -> Ollama isn't running: start "Ollama" from the Start menu.
  Ears red    -> run "Install Spark.bat" again.
  Voice amber -> no Piper voice found (it uses the Windows voice instead);
                 run "Install Spark.bat" again.
Slow replies? Check the graphics card is being used: in a terminal run
  ollama ps
The PROCESSOR column should say "100% GPU". If not, update the NVIDIA
driver, or pick llama3.2:3b.

The small window that opens with Spark shows what's happening.
Close it to quit Spark.
